# Values Terraform prints after `terraform apply`.

output "bucket_name" {
  description = "Name of the S3 bucket that holds the website."
  value       = aws_s3_bucket.site.id
}

output "website_url" {
  description = "Open this in your browser to see the site."
  value       = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
}
