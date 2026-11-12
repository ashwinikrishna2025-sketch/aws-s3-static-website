# Inputs you can change without editing the main code.
# Override them in a terraform.tfvars file (see terraform.tfvars.example).

variable "aws_region" {
  description = "AWS region to create the bucket in."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as the start of the bucket name. Lowercase letters, numbers and hyphens only."
  type        = string
  default     = "my-static-site"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}[a-z0-9]$", var.project_name))
    error_message = "project_name must be 3-42 characters: lowercase letters, numbers and hyphens, not starting or ending with a hyphen."
  }
}

# --- App configuration ---
# These values are written into config.json, which the website reads and shows.
# Change one, run `terraform plan`, and you'll see exactly what would be updated.

variable "app_environment" {
  description = "Which environment this deployment is, shown on the site."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.app_environment)
    error_message = "app_environment must be one of: dev, test, prod."
  }
}

variable "app_version" {
  description = "Version label shown on the site."
  type        = string
  default     = "1.0.0"
}

variable "welcome_message" {
  description = "A short message shown on the home page."
  type        = string
  default     = "Configured by Terraform!"
}

# --- Custom domain (optional) ---
# Leave both empty to use the default S3 website address.
# You must already own the domain; Terraform does not buy it for you.

variable "domain_name" {
  description = "Full address the site should answer on, e.g. \"www.example.com\". Empty = no custom domain."
  type        = string
  default     = ""

  validation {
    condition     = var.domain_name == "" || can(regex("^([a-z0-9]([a-z0-9-]*[a-z0-9])?[.])+[a-z]{2,}$", var.domain_name))
    error_message = "domain_name must be a lowercase domain such as www.example.com (no http://, no trailing slash)."
  }

  validation {
    condition     = var.domain_name == "" || var.hosted_zone_name != ""
    error_message = "Set hosted_zone_name as well when domain_name is set."
  }

  validation {
    condition     = var.domain_name == "" || var.domain_name == var.hosted_zone_name || endswith(var.domain_name, ".${var.hosted_zone_name}")
    error_message = "domain_name must be the hosted zone's domain or a subdomain of it (e.g. www.example.com in example.com)."
  }
}

variable "hosted_zone_name" {
  description = "The domain you own, e.g. \"example.com\". A Route 53 hosted zone is created for it."
  type        = string
  default     = ""
}
