terraform {
  required_version = ">= 1.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.61"
    }
  }
  backend "s3" {
    bucket = var.aws.bucket
    key    = var.aws.key
    region = var.aws.region
  }
}

data "aws_caller_identity" "this" {}

data "tls_certificate" "this" {
  count = 1
  url   = var.github.url
}

resource "aws_iam_openid_connect_provider" "this" {
  url             = var.github.url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.this[0].certificates[*].sha1_fingerprint
}

locals {
  role_files = fileset("${path.root}/roles", "**/*.yml")
  roles = {
    for file in local.role_files :
    replace(trimsuffix(file, ".yml"), "/", "_") => yamldecode(file("${path.root}/roles/${file}"))
  }
  user_files = fileset("${path.root}/users", "**/*.yml")
  users = {
    for file in local.user_files :
    replace(trimsuffix(file, ".yml"), "/", "_") => yamldecode(file("${path.root}/users/${file}"))
  }
}

module "github_roles" {
  source       = "./modules/role"
  for_each     = local.roles
  account_id   = data.aws_caller_identity.this.account_id
  assume_role  = try(each.value["assume_role"], null)
  url          = var.github.url
  name         = each.value["name"]
  matcher      = try(each.value["matcher"], "StringEquals")
  repositories = try(each.value["repositories"], [])
  branches     = try(each.value["branches"], [])
  tags         = try(each.value["tags"], [])
  environments = try(each.value["environments"], [])
  policies     = each.value["policies"]
}

module "users" {
  source   = "./modules/user"
  for_each = local.users

  account_id = data.aws_caller_identity.this.account_id
  name       = each.value["name"]
  policies   = each.value["policies"]
}
