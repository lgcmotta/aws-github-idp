output "github_assume_role_arns" {
  value       = [for role in module.github_roles : role.assume_role_arn]
  description = "ARNs from the created AWS roles to be assumed"
}
