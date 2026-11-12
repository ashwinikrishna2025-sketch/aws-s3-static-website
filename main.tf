# The actual infrastructure: an S3 bucket that serves a website.

# S3 bucket names must be unique across ALL of AWS, so we add a random suffix.
resource "random_id" "suffix" {
  byte_length = 4
}

# 1. The bucket that stores the website files.
resource "aws_s3_bucket" "site" {
  bucket = "${var.project_name}-${random_id.suffix.hex}"

  # Lets `terraform destroy` delete the bucket even if it still has files in it.
  force_destroy = true
}

# 2. Turn on "static website hosting" for the bucket.
resource "aws_s3_bucket_website_configuration" "site" {
  bucket = aws_s3_bucket.site.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# 3. By default AWS blocks all public access to buckets (a good safety default).
#    A public website has to be readable by everyone, so we allow a public
#    bucket POLICY here - but still block public ACLs.
resource "aws_s3_bucket_public_access_block" "site" {
  bucket = aws_s3_bucket.site.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

# 4. The policy that lets anyone on the internet READ (but not change) the files.
data "aws_iam_policy_document" "public_read" {
  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.site.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.site.id
  policy = data.aws_iam_policy_document.public_read.json

  # The public access block must be relaxed before AWS accepts a public policy.
  depends_on = [aws_s3_bucket_public_access_block.site]
}

# 5. Upload every file in the website/ folder to the bucket.
locals {
  website_dir = "${path.module}/website"

  # Tells browsers what kind of file each one is, based on its extension.
  content_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    json = "application/json"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    gif  = "image/gif"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
    txt  = "text/plain"
  }
}

resource "aws_s3_object" "site_files" {
  for_each = fileset(local.website_dir, "**")

  bucket       = aws_s3_bucket.site.id
  key          = each.value
  source       = "${local.website_dir}/${each.value}"
  content_type = lookup(local.content_types, lower(element(split(".", each.value), length(split(".", each.value)) - 1)), "application/octet-stream")

  # The etag changes when the file changes, so Terraform re-uploads edited files.
  etag = filemd5("${local.website_dir}/${each.value}")

  # Make browsers check for a newer version on every visit, so edits show up
  # without a hard refresh.
  cache_control = "no-cache"
}

# 6. App configuration. Terraform builds a small JSON file from the variables
#    in variables.tf and uploads it next to the website. The page loads
#    config.json in the browser and shows the values.
locals {
  app_config = {
    environment     = var.app_environment
    version         = var.app_version
    welcome_message = var.welcome_message
    region          = var.aws_region
    bucket          = aws_s3_bucket.site.id
  }
}

resource "aws_s3_object" "app_config" {
  bucket       = aws_s3_bucket.site.id
  key          = "config.json"
  content      = jsonencode(local.app_config)
  content_type = "application/json"

  # Always fetch the latest config instead of a copy the browser saved earlier.
  cache_control = "no-cache"
}
