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
