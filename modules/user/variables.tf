variable "account_id" {
  type        = string
  description = "AWS account containing the application user and role"
}

variable "name" {
  type        = string
  description = "Base name for the application user, role, and policies"
}

variable "policies" {
  type = map(object({
    name = string
    statements = list(object({
      sid       = string
      effect    = string
      actions   = list(string)
      resources = list(string)
      conditions = optional(list(object({
        matcher  = string
        values   = list(string)
        variable = string
      })), [])
    }))
  }))
  description = "Named policy groups attached to the application role"
}
