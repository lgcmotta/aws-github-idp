resource "aws_iam_user" "this" {
  name = "${var.name}ApplicationUser"
}

module "role" {
  source = "../role"

  account_id   = var.account_id
  name         = "${var.name}Application"
  url          = ""
  matcher      = "StringEquals"
  repositories = []
  assume_role = {
    principals = [aws_iam_user.this.arn]
  }
  policies = var.policies
}

data "aws_iam_policy_document" "this" {
  statement {
    sid       = "AssumeApplicationRole"
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    resources = [module.role.assume_role_arn]
  }
}

resource "aws_iam_user_policy" "this" {
  name   = "${var.name}AssumeApplicationRolePolicy"
  user   = aws_iam_user.this.name
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name

  depends_on = [aws_iam_user_policy.this, module.role]
}
