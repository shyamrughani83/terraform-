output "pipeline_name" {
  description = "Name of the CodePipeline"
  value       = aws_codepipeline.main.name
}

output "github_connection_status" {
  description = "Status of the GitHub connection"
  value       = aws_codestarconnections_connection.github.connection_status
}

output "github_connection_arn" {
  description = "ARN of the GitHub connection"
  value       = aws_codestarconnections_connection.github.arn
}
