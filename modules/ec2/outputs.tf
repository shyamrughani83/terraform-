output "instance_ids" {
  description = "IDs of the EC2 instances"
  value       = aws_instance.app_server[*].id
}

output "instance_public_ips" {
  description = "Public IPs of the EC2 instances"
  value       = aws_eip.app_server[*].public_ip
}
