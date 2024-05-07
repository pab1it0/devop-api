output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.cloudfront.domain_name
}

output "static_files_bucket_name" {
  value = aws_s3_bucket.static_files_bucket.bucket
}
