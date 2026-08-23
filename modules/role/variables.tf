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

variable "statements" {
  type = list(object({
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
  description = "A list of IAM policy statements to attach to the role"
}
