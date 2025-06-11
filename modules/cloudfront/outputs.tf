output "s3_bucket_name" {
  description = "Name of the S3 bucket for static website"
  value       = aws_s3_bucket.static_website.bucket
}

output "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution"
  value       = aws_cloudfront_distribution.static_website.domain_name
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.static_website.id
}

output "static_pipeline_name" {
  description = "Name of the static website pipeline"
  value       = aws_codepipeline.static_website.name
}

output "static_github_connection_arn" {
  description = "ARN of the GitHub connection for static website"
  value       = aws_codestarconnections_connection.static_github.arn
}

output "static_github_connection_status" {
  description = "Status of the GitHub connection for static website"
  value       = aws_codestarconnections_connection.static_github.connection_status
}
