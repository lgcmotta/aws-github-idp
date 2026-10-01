locals {
  policy_prefix = var.assume_role == null ? "${var.name}GitHub" : var.name
  role          = var.assume_role == null ? "${var.name}GitHubRole" : "${var.name}Role"
}

data "aws_iam_policy_document" "this" {
  version = "2012-10-17"

  dynamic "statement" {
    for_each = var.assume_role == null ? [true] : []
    content {
      effect = "Allow"
      principals {
        type        = "Federated"
        identifiers = ["arn:aws:iam::${var.account_id}:oidc-provider/token.actions.githubusercontent.com"]
      }
      actions = [
        "sts:AssumeRoleWithWebIdentity"
      ]
      condition {
        test     = "StringEquals"
        values   = ["sts.amazonaws.com"]
        variable = "token.actions.githubusercontent.com:aud"
      }
      condition {
        test = var.matcher
        values = flatten([
          for repository in var.repositories :
          concat(
            [for branch in var.branches : "repo:${repository}:ref:refs/heads/${branch}"],
            [for tag in var.tags : "repo:${repository}:ref:refs/tags/${tag}"],
            [for environment in var.environments : "repo:${repository}:environment:${environment}"]
          )
        ])
        variable = "token.actions.githubusercontent.com:sub"
      }
    }
  }

  dynamic "statement" {
    for_each = var.assume_role == null ? [] : [var.assume_role]
    content {
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = statement.value.principals
      }
      actions = [
        "sts:AssumeRole"
      ]
      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.matcher
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_iam_role" "this" {
  name               = local.role
  assume_role_policy = data.aws_iam_policy_document.this.json

  lifecycle {
    precondition {
      condition = var.assume_role == null || (
        length(var.repositories) == 0
        && length(var.branches) == 0
        && length(var.tags) == 0
        && length(var.environments) == 0
      )
      error_message = "AssumeRole roles cannot define GitHub repositories, branches, tags, or environments."
    }
  }
}

data "aws_iam_policy_document" "role_policies" {
  for_each = var.policies

  dynamic "statement" {
    for_each = each.value.statements
    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
      dynamic "condition" {
        for_each = statement.value.conditions
        content {
          test     = condition.value.matcher
          values   = condition.value.values
          variable = condition.value.variable
        }
      }
    }
  }
}

resource "aws_iam_policy" "this" {
  for_each = var.policies

  name   = "${local.policy_prefix}${each.value.name}Policy"
  policy = data.aws_iam_policy_document.role_policies[each.key].json

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = length("${local.policy_prefix}${each.value.name}Policy") <= 128
      error_message = "Generated IAM policy names must not exceed 128 characters."
    }

    precondition {
      condition     = length(jsonencode(jsondecode(data.aws_iam_policy_document.role_policies[each.key].json))) <= 6144
      error_message = "Each managed policy must fit within 6,144 characters. Split oversized groups into smaller policies."
    }
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = var.policies

  policy_arn = aws_iam_policy.this[each.key].arn
  role       = aws_iam_role.this.name
}
