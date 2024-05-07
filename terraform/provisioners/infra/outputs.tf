output "aws_region" {
  value = var.aws_region
}

output "aws_account" {
  value = var.aws_account
}

output "static_files_bucket_name" {
  value = module.devops_api_cloudfront.static_files_bucket_name
}

output "cloudfront_domain_name" {
  value = module.devops_api_cloudfront.cloudfront_domain_name
}
