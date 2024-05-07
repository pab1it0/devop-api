variable "env_id" {
  description = "Environment id same as terraform workspace"
}

variable "aws_region" {
  description = "Aws region"
}

variable "aws_account" {
  description = "AWS account"
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