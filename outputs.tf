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
