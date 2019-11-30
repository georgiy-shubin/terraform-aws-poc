output "aws_s3_bucket_website_endpoint" {
  value = aws_s3_bucket.webbucket.website_endpoint
}

output "website_address" {
  value = aws_route53_record.website.name
}

# output "aws_s3_empty_bucket_command" {
#   value = format("aws s3 rm s3://%s --recursive --profile %s", aws_s3_bucket.webbucket.id, var.aws_profile)
# }


# output "aws_s3_upload_folder_command" {
#   value = format("aws s3 cp %s s3://%s/ --recursive --profile %s", var.path_to_html5, aws_s3_bucket.webbucket.id, var.aws_profile)
# }
