
############################
####  Common Variables  ####
############################

# Tags
variable "tag_name" {
  type        = string
  description = "The tag, visible in the NAME column"
}

# Terraform version
variable "tfversion" {
  type        = string
  description = "Terraform Version"
  default     = "0.12.15"
}

#####################
####  Providers  ####
#####################

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile created with the 'aws configure' command"
  default     = "default"
}

###################
####  Network  ####
###################

# Network
variable "vpc_cidr" {
  type        = string
  description = "The CIDR Block for entire VPC"
}

# Security Group
variable "ingress_ports" {
  type        = list(number)
  description = "Network ports"
}

variable "protocol" {
  type        = string
  description = "Network protocol"
}

###################
####  Route53  ####
###################

variable "domain_name" {
  type        = string
  description = "Registered domain name"
}

##############
#### EC2 #####
##############

# EC2 Key Pairs
variable "key_pair" {
  type        = string
  description = "Key Pair to connect to an EC2 instance"
}

# EC2 Instance
variable "instance_type" {
  type        = string
  description = "Flavor t2.micro, t2.small"
  default     = "t2.micro"
}

