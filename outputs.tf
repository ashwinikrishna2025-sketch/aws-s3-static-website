# Values Terraform prints after `terraform apply`.

output "bucket_name" {
  description = "Name of the S3 bucket that holds the website."
  value       = aws_s3_bucket.site.id
}

output "website_url" {
  description = "Open this in your browser to see the site."
  value       = "http://${aws_s3_bucket_website_configuration.site.website_endpoint}"
}

output "app_config" {
  description = "The settings written to config.json and shown on the site."
  value       = local.app_config
}

output "custom_domain_url" {
  description = "The site's address on your own domain (null when no custom domain is set)."
  value       = local.use_custom_domain ? "http://${var.domain_name}" : null
}

output "name_servers" {
  description = "Enter these at your domain registrar so the domain uses Route 53 (null when no custom domain is set)."
  value       = local.use_custom_domain ? aws_route53_zone.site[0].name_servers : null
}
