terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.46.0"
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


module "devops_api_cloudfront" {
  source          = "../../modules/aws-cloudfront"
  resource_prefix = "${var.env_id}-devops-api"
  ecs_lb_edpoint  = module.ecs.ecs_lb_edpoint
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "devops-api-vpc"
  cidr = "10.31.0.0/16"

  azs             = formatlist("${var.aws_region}%s", ["a", "b", "c"])
  private_subnets = ["10.31.1.0/24", "10.31.2.0/24", "10.31.3.0/24"]
  public_subnets  = ["10.31.101.0/24", "10.31.102.0/24", "10.31.103.0/24"]

  enable_nat_gateway = true
}

module "ecs" {
  source                = "../../modules/aws-ecs-cluster"
  resource_prefix       = "${var.env_id}-devops-api"
  vpc_id                = module.vpc.vpc_id
  vpc_cidr_block        = module.vpc.vpc_cidr_block
  private_subnets       = module.vpc.private_subnets
  public_subnets        = module.vpc.public_subnets
  container_port        = var.container_port
  devops_api_image_name = var.devops_api_image_name
  devops_api_ecr_arn    = var.devops_api_ecr_arn
  aws_region            = var.aws_region
}

