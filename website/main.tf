# Provider
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile
}

# S3
resource "aws_s3_bucket" "webbucket" {
  bucket = format("%s.%s", var.subdomain_name, var.domain_name)
  acl    = "public-read"
  website {
    index_document = "index.html"
  }
  # provisioner "local-exec" {
  #   command = format("aws s3 cp %s s3://%s/ --recursive --profile %s", var.path_to_html5, aws_s3_bucket.webbucket.id, var.aws_profile)
  # }
}

resource "aws_s3_bucket_object" "website" {
  for_each     = fileset(var.path_to_html5, "**")
  bucket       = aws_s3_bucket.webbucket.id
  key          = each.value
  source       = format("%s%s", var.path_to_html5, each.value)
  content_type = lookup(var.mime_types, element(split(".", basename(each.value)), length(split(".", basename(each.value))) - 1), "")
  # content_type = "image/svg+xml"
  etag = filemd5(format("%s%s", var.path_to_html5, each.value))
  # html5up-massively /12
}

resource "aws_s3_bucket_policy" "webbucket" {
  bucket = aws_s3_bucket.webbucket.id
  policy = jsonencode(
    {
      Id = "WebBucketPolicyId"
      Statement = [
        {
          Action    = "s3:GetObject"
          Effect    = "Allow"
          Principal = "*"
          Resource  = "${aws_s3_bucket.webbucket.arn}/*"
          Sid       = "WebBucketPolicy"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

data "aws_route53_zone" "hz" {
  name = format("%s.", var.domain_name)
}

resource "aws_route53_record" "website" {
  zone_id = data.aws_route53_zone.hz.zone_id
  name    = aws_s3_bucket.webbucket.id
  type    = "A"

  alias {
    name                   = aws_s3_bucket.webbucket.website_domain
    zone_id                = aws_s3_bucket.webbucket.hosted_zone_id
    evaluate_target_health = false
  }
}