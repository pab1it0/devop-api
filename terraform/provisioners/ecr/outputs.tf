output "provision_api_ecr_repository_url" {
  value = module.provision_api_ecr_repo.ecr_repository_url
}

output "aws_region" {
  value = var.aws_region
}

output "aws_account" {
  value = var.aws_account
}