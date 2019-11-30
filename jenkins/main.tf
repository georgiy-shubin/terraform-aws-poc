#
#  AWS provider
#    Arguments:
#       1. Region (Required) - Passed as a variable.
#       2. Profile (Optional) - The profile of shared credentials set with the 'aws configure --profile' command. Passed as a variable.
#

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

#
#  Data sources
#    1. aws_availability_zones - Gets the list of active Availability Zones within an AWS Region. Used for dynamic subnet creation.
#    2. aws_subnet_ids - Gets the list of subnets within a VPC. Used by EC2 Instance, which picks up one subnet.
#    3. aws_ami - Finds an AWS AMI based on provided filters. Used by EC2 Instance.
#

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnet_ids" "subnets" {
  vpc_id     = aws_vpc.vpc.id
  depends_on = [aws_subnet.subnet]
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-eoan-19.10-amd64-server-*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#
#  Network structure:
#     * VPC, Internet Gateway, Subnet in each Availability Zone, Security Group
#
#    1. The aws_vpc resource creates a new VPC with CIDR block passed as a variable. The default VPC Route Table is used.
#    2. aws_internet_gateway - Creates a new Internet Gateway.
#    3. aws_route - Creates the route to the public through the Internet Gateway for the default VPC Route Table.
#    4. aws_subnet - Creates a subnet in each Availability Zone within an AWS Region for the new VPC.
#       Dynamic subnet nubmer is contolled by "for_each = toset(data.aws_availability_zones.available.zone_ids)".
#       The subnet CIDR is generated by "cidrsubnet(aws_vpc.vpc.cidr_block, 8, regex("\\d", strrev(each.value)))" based on the VPC CIDR and AZs ordinal number passed through "each.value".
#       Example for the VPC CIDR = "10.10.0.0/16":
#               > terraform console
#               [J> cidrsubnet("10.10.0.0/16", 8, regex("\\d", strrev("euc1-az1")))
#               10.10.1.0/24
#               [J> cidrsubnet("10.10.0.0/16", 8, regex("\\d", strrev("euc1-az2")))
#               10.10.2.0/24
#               [J> cidrsubnet("10.10.0.0/16", 8, regex("\\d", strrev("euc1-az3")))
#               10.10.3.0/24
#    5. aws_security_group - Creates a security group with the dynamic ingress rule based on the port list passed through the "ingress_ports" variable.
#

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.tag_name
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.tag_name
  }
}

resource "aws_route" "igw-route" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_subnet" "subnet" {
  for_each                        = toset(data.aws_availability_zones.available.zone_ids)
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, regex("\\d", strrev(each.value)))
  availability_zone_id            = each.value
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = false
  tags = {
    Name = var.tag_name
  }
}

resource "aws_security_group" "sec-group" {
  name        = var.tag_name
  description = var.tag_name
  vpc_id      = aws_vpc.vpc.id
  dynamic "ingress" {
    for_each = var.ingress_ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = var.protocol
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = var.tag_name
  }
}

#
#  Route53
#     Prerequisite: A domain purchased from AWS Route53 used in the example.
#
#    1. aws_route53_delegation_set - Creates a Route53 Reusable Delegation Set.
#       The local_exec provisioner updates name servers of the domain once the Delegation Set is created.
#       Example:
#               aws route53domains --profile <profile> --region us-east-1 update-domain-nameservers --domain <domain_name> --nameservers Name=ns-1309.awsdns-35.org Name=ns-1980.awsdns-55.co.uk Name=ns-48.awsdns-06.com Name=ns-668.awsdns-19.net
#    2. aws_route53_zone - Creates a Hosted Zone for domain passed through a variable. Name servers are assigned though the Delegation Set.
#    3. aws_route53_record - Creates the jenkins.<domain_name> A record for the Public IP of the EC2 Instance.
#

resource "aws_route53_delegation_set" "delegation-set" {
  reference_name = var.tag_name
  provisioner "local-exec" {
    command = format("aws route53domains --profile %s --region us-east-1 update-domain-nameservers --domain %s --nameservers Name=%s", var.aws_profile, var.domain_name, join(" Name=", aws_route53_delegation_set.delegation-set.name_servers))
  }
}

resource "aws_route53_zone" "hosted-zone" {
  name              = var.domain_name
  delegation_set_id = aws_route53_delegation_set.delegation-set.id
}

resource "aws_route53_record" "jenkins" {
  zone_id = aws_route53_zone.hosted-zone.zone_id
  name    = format("jenkins.%s", var.domain_name)
  type    = "A"
  ttl     = "300"
  records = [aws_instance.jenkins-instnace.public_ip]
}

#
#  EC2
#      Prerequisite: An SSH key must be created in the same folder where terraform files located.
#
#    1. aws_key_pair - Uploads the pre-created SSH public key to AWS
#    2. aws_instance - Creates an EC2 Instance with Ubuntu, and installs Jenkins, Terraform and AWS CLI
#

resource "aws_key_pair" "ssh-keypair" {
  key_name   = var.key_pair
  public_key = file(format("%s.pub", var.key_pair))
}

resource "aws_instance" "jenkins-instnace" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = tolist(data.aws_subnet_ids.subnets.ids)[0]
  vpc_security_group_ids = [aws_security_group.sec-group.id]
  key_name               = aws_key_pair.ssh-keypair.key_name
  depends_on             = [aws_subnet.subnet]
  user_data              = <<-EOF
  #!/bin/bash
  wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | apt-key add -
  sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
  apt-get update
  apt-get install -y default-jre unzip python-pip
  apt-get install -y jenkins
  wget -q https://releases.hashicorp.com/terraform/${var.tfversion}/terraform_${var.tfversion}_linux_amd64.zip \
  && unzip -o terraform_${var.tfversion}_linux_amd64.zip -d /usr/local/bin \
  && rm terraform_${var.tfversion}_linux_amd64.zip
  pip install awscli
  EOF
  tags = {
    Name = var.tag_name
  }
}
