output "assume_role_arn" {
  value       = aws_iam_role.this.arn
  description = "The assume role with web identity"
}
