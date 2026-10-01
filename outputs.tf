output "github_assume_role_arns" {
  value = [
    for key, role in module.github_roles : role.assume_role_arn
    if try(local.roles[key]["assume_role"], null) == null
  ]
  description = "ARNs of the created GitHub web identity roles"
}

output "assume_role_arns" {
  value = [
    for key, role in module.github_roles : role.assume_role_arn
    if try(local.roles[key]["assume_role"], null) != null
  ]
  description = "ARNs of the created AWS-principal AssumeRole roles"
}

output "user_credentials" {
  value = {
    for key, user in module.users : key => {
      AWS_ACCESS_KEY_ID     = user.access_key_id
      AWS_SECRET_ACCESS_KEY = user.secret_access_key
    }
  }
  description = "Sensitive Railway credentials, keyed by user definition"
  sensitive   = true
}

output "user_arns" {
  value       = { for key, user in module.users : key => user.user_arn }
  description = "Application IAM user ARNs, keyed by user definition"
}

output "user_role_arns" {
  value       = { for key, user in module.users : key => user.role_arn }
  description = "Application role ARNs for AWS_ROLE_ARN, keyed by user definition"
}

output "aws_region" {
  value       = var.aws.region
  description = "AWS_REGION for application resource requests"
}
