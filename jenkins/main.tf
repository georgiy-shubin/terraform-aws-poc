#####################
####  Providers  ####
#####################

provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}


########################
####  Data sources  ####
########################

# Network DS
data "aws_availability_zones" "available" {
  state = "available"
}

# Subnet IDs DS
data "aws_subnet_ids" "subnets" {
  vpc_id     = aws_vpc.vpc.id
  depends_on = [aws_subnet.subnet]
}

# EC2 DS
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


###################
####  Network  ####
###################

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = var.tag_name
  }
}

# Subnets
resource "aws_subnet" "subnet" {
  for_each                        = toset(data.aws_availability_zones.available.zone_ids)
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = cidrsubnet(aws_vpc.vpc.cidr_block, 8, regex("\\d", strrev(each.value)))
  availability_zone_id            = each.value
  map_public_ip_on_launch         = true
  assign_ipv6_address_on_creation = false
  tags = {
    Name  = var.tag_name
    Az_Id = each.value
  }
}

# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = var.tag_name
  }
}

# Route
resource "aws_route" "igw-route" {
  route_table_id         = aws_vpc.vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Security Group
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

###################
####  Route53  ####
###################

resource "aws_route53_delegation_set" "delegation-set" {
  reference_name = "gs"
}

resource "aws_route53_zone" "hosted-zone" {
  name              = var.domain_name
  delegation_set_id = aws_route53_delegation_set.delegation-set.id
  provisioner "local-exec" {
    command = format("aws route53domains --profile %s --region us-east-1 update-domain-nameservers --domain %s --nameservers Name=%s", var.aws_profile, var.domain_name, join(" Name=", aws_route53_zone.hosted-zone.name_servers))
  }
}

resource "aws_route53_record" "jenkins" {
  zone_id = aws_route53_zone.hosted-zone.zone_id
  # name    = join("", ["jenkins.", var.domain_name])
  name    = format("jenkins.%s", var.domain_name)
  type    = "A"
  ttl     = "300"
  records = [aws_instance.jenkins-instnace.public_ip]
}

##############
#### EC2 #####
##############

# EC2 Key Pairs
resource "aws_key_pair" "ssh-keypair" {
  key_name = var.key_pair
  # public_key = file(join("", [var.key_pair, ".pub"]))
  public_key = file(format("%s.pub", var.key_pair))
}

# EC2 Instance
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
