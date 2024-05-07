output "devops_api_ecr_repository_url" {
  value = module.devops_api_ecr_repo.ecr_repository_url
}

output "ecr_repository_arn" {
  value = module.devops_api_ecr_repo.ecr_repository_arn
}

output "aws_region" {
  value = var.aws_region
}

output "aws_account" {
  value = var.aws_account
}