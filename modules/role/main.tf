locals {
  policy = "${var.name}GitHubPolicy"
  role   = "${var.name}GitHubRole"
}

data "aws_iam_policy_document" "this" {
  version = "2012-10-17"
  statement {
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

resource "aws_iam_role" "this" {
  name               = local.role
  assume_role_policy = data.aws_iam_policy_document.this.json
}

data "aws_iam_policy_document" "role_policies" {
  dynamic "statement" {
    for_each = var.statements
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
  name   = local.policy
  policy = data.aws_iam_policy_document.role_policies.json
}

resource "aws_iam_role_policy_attachment" "this" {
  policy_arn = aws_iam_policy.this.arn
  role       = aws_iam_role.this.name
}
