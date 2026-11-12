# One-time setup: creates the S3 bucket that stores Terraform's state file
# for the main project.
#
# Why a separate folder? The main project keeps its state IN this bucket, so
# the bucket has to exist before the main project can use it. This small
# config creates it, and keeps its own (tiny) state file locally in this folder.
#
# Run it once:
#   cd bootstrap
#   terraform init
#   terraform apply

terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

variable "aws_region" {
  description = "AWS region to create the state bucket in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as the start of the state bucket name."
  type        = string
  default     = "my-static-site"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
      Purpose   = "terraform-state"
    }
  }
}

# Bucket names must be unique across ALL of AWS, so we add a random suffix.
resource "random_id" "suffix" {
  byte_length = 4
}

resource "aws_s3_bucket" "state" {
  bucket = "${var.project_name}-tfstate-${random_id.suffix.hex}"

  # Safety net: Terraform refuses to delete this bucket, because losing the
  # state file means Terraform forgets what it created.
  lifecycle {
    prevent_destroy = true
  }
}

# Keep every old version of the state file, so a bad change can be rolled back.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Encrypt the state file at rest. State can contain sensitive values.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Unlike the website bucket, this one must never be public.
resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

# Old versions pile up over time; delete ones older than 90 days.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "expire-old-state-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

output "state_bucket_name" {
  description = "Put this name in the backend block in ../versions.tf."
  value       = aws_s3_bucket.state.id
}
