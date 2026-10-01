variable "account_id" {
  type        = string
  description = "The AWS account id containing GitHub as the IDP"
}

variable "assume_role" {
  type = object({
    principals = list(string)
    conditions = optional(list(object({
      matcher  = string
      values   = list(string)
      variable = string
    })), [])
  })
  description = "AWS principals and optional conditions allowed to assume this role"
  default     = null

  validation {
    condition     = var.assume_role == null ? true : length(var.assume_role.principals) > 0
    error_message = "The variable \"assume_role.principals\" must contain at least one AWS principal."
  }
}

variable "name" {
  type        = string
  description = "Name of the Policy/Role to be assumed"
}

variable "url" {
  type        = string
  description = "The GitHub OIDC host URL"
}

variable "repositories" {
  type        = list(string)
  description = "The GitHub repositories in OWNER/REPO format. Wildcards (*) are allowed when using StringLike"
}

variable "matcher" {
  type        = string
  description = "The AWS IAM condition operator"
  validation {
    condition     = contains(["StringEquals", "StringLike"], var.matcher)
    error_message = "The variable \"matcher\" must be either \"StringEquals\" or \"StringLike\"."
  }
}

variable "branches" {
  type        = list(string)
  description = "A list of git branches that are allowed to assume the role with web identity"
  default     = []
}

variable "tags" {
  type        = list(string)
  description = "A list of git tags that are allowed to assume the role with web identity"
  default     = []
}

variable "environments" {
  type        = list(string)
  description = "A list of GitHub environments that are allowed to assume the role with web identity"
  default     = []
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
  description = "Named groups of statements, each attached to the role as a separate managed policy"

  validation {
    condition     = length(var.policies) > 0 && length(var.policies) <= 20
    error_message = "Define between 1 and 20 policy groups, within the default managed-policy attachment quota."
  }

  validation {
    condition     = length(distinct([for policy in values(var.policies) : lower(policy.name)])) == length(var.policies)
    error_message = "Policy group names must be unique, ignoring case."
  }

  validation {
    condition     = alltrue([for policy in values(var.policies) : can(regex("^[A-Za-z0-9+=,.@_-]+$", policy.name))])
    error_message = "Policy group names must be nonempty and contain only IAM policy name characters."
  }

  validation {
    condition     = alltrue([for policy in values(var.policies) : length(policy.statements) > 0])
    error_message = "Every policy group must contain at least one statement."
  }
}
