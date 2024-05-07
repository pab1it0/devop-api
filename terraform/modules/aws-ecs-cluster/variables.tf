variable "resource_prefix" {
  description = "Resource prefix"
}

variable "private_subnets" {
  description = "Private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "Public subnets"
  type        = list(string)
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block"
}

variable "container_port" {
  description = "Container port"
}

variable "devops_api_image_name" {
  description = "DevOps API image name"
}

variable "devops_api_ecr_arn" {
  description = "DevOps API ECR ARN"
}

variable "vpc_id" {
  description = "VPC ID"
}

variable "aws_region" {
  description = "AWS region"
}