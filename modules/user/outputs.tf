output "access_key_id" {
  value       = aws_iam_access_key.this.id
  description = "Access key ID for the application's initial authentication"
  sensitive   = true
}

output "secret_access_key" {
  value       = aws_iam_access_key.this.secret
  description = "Secret access key for the application's initial authentication"
  sensitive   = true
}

output "user_arn" {
  value       = aws_iam_user.this.arn
  description = "ARN of the application IAM user"
}

output "role_arn" {
  value       = module.role.assume_role_arn
  description = "ARN of the role the application user can assume"
}

output "policy_arns" {
  value       = module.role.policy_arns
  description = "ARNs of the role policies, keyed by policy group"
}
