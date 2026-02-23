terraform {
  required_version = ">= 1.10"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.33"
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
  client_id_list  = [var.github.url]
  thumbprint_list = data.tls_certificate.this[0].certificates[*].sha1_fingerprint
}

locals {
  role_files = fileset("${path.root}/roles", "**/*.yml")
  roles = {
    for file in local.role_files :
    replace(trimsuffix(file, ".yml"), "/", "_") => yamldecode(file("${path.root}/roles/${file}"))
  }
}

module "github_roles" {
  source       = "./modules/role"
  for_each     = local.roles
  account_id   = data.aws_caller_identity.this.account_id
  url          = var.github.url
  name         = each.value["name"]
  matcher      = each.value["matcher"]
  repositories = try(each.value["repositories"], [])
  branches     = try(each.value["branches"], [])
  tags         = try(each.value["tags"], [])
  statements   = try(each.value["statements"], [])
}
