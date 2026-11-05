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
