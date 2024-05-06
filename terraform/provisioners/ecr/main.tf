terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.24.0"
    }
  }
  required_version = ">= 1.0"
}

locals {
  shared_tags = {
    env_id = var.env_id
    region = var.aws_region
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = local.shared_tags
  }
}

module "provision_api_ecr_repo" {
  source          = "../../modules/aws-ecr"
  resource_prefix = "${var.env_id}-devops-api"
  tag_mutability  = "IMMUTABLE"
}
