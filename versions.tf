# Which Terraform version and which "providers" (plugins) this project needs.
# A provider is how Terraform talks to a service - here, AWS.

terraform {
  required_version = ">= 1.10.0"

  # Where Terraform keeps its "state" - its record of what it has created.
  # Storing it in S3 (instead of a file on one PC) means it is backed up,
  # versioned, and could be shared by a team.
  #
  # The bucket is created once by the config in bootstrap/. If you fork this
  # project, run that first and put your own bucket name here. (Backend
  # settings can't use variables, so the name has to be written out.)
  backend "s3" {
    bucket  = "my-static-site-tfstate-5128adf5"
    key     = "static-website/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true

    # Locks the state while a command runs, so two people (or two terminals)
    # can't change the infrastructure at the same time.
    use_lockfile = true
  }

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

provider "aws" {
  region = var.aws_region

  # These tags are added to every AWS resource this project creates,
  # so you can always find (and clean up) what Terraform made.
  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "Terraform"
    }
  }
}
