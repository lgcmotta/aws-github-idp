output "assume_role_arn" {
  value       = aws_iam_role.this.arn
  description = "ARN of the created AWS IAM role"
}

output "policy_arns" {
  value       = { for key, policy in aws_iam_policy.this : key => policy.arn }
  description = "ARNs of the managed policies, keyed by policy group"
}
