variable "tag_name" {
  type        = string
  description = "The tag, visible in the NAME column"
}

variable "tfversion" {
  type        = string
  description = "Terraform Version"
  default     = "0.12.16"
}

variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile created with the 'aws configure' command"
  default     = "default"
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR Block for entire VPC"
}

variable "ingress_ports" {
  type        = list(number)
  description = "Network ports"
  default     = [22, 8080]
}

variable "protocol" {
  type        = string
  description = "Network protocol"
  default     = "TCP"
}

variable "domain_name" {
  type        = string
  description = "Registered domain name"
}

variable "key_pair" {
  type        = string
  description = "Key Pair to connect to an EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "Flavor t2.micro, t2.small"
  default     = "t2.micro"
}

