# Provider
variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "aws_profile" {
  type        = string
  description = "AWS Profile created with the 'aws configure' command"
  default     = "default"
}

# S3
# variable "aws_s3_bucket_name" {
#   type        = string
#   description = "AWS S3 Backup Name. Must be unique across AWS"
# }

variable "path_to_html5" {
  type        = string
  description = "Path to the html files to upload to the web hosting bucket"
}

###################
####  Route53  ####
###################

variable "domain_name" {
  type        = string
  description = "Registered domain name"
}

variable "subdomain_name" {
  type        = string
  description = "Registered domain name"
}

variable "mime_types" {
  default = {
    css   = "text/css"
    eot   = "application/vnd.ms-fontobject"
    html  = "text/html"
    jpg   = "image/jpeg"
    js    = "application/javascript"
    png   = "image/png"
    scss  = "application/javascript"
    svg   = "image/svg+xml"
    ttf   = "font/ttf"
    txt   = "text/plain"
    woff  = "font/woff"
    woff2 = "font/woff2"
  }
}
