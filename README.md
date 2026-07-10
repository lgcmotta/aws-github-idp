# AWS Identity Provider for GitHub Actions

OpenTofu configuration for managing AWS Identity and Access Management (IAM) OpenID Connect (OIDC) integration for GitHub Actions.

This repository defines:

- an AWS IAM OIDC provider for GitHub Actions;
- a reusable IAM role module for GitHub Actions federation;
- a schema for role definition files;
- root outputs for the managed role ARNs.

## Architecture

The root module creates the GitHub Actions OIDC provider and loads deployment-specific role definitions into the `modules/role` module. Each generated role uses GitHub OIDC trust conditions and attaches an IAM policy built from the role definition.

Role definitions are environment-specific configuration and are not intended to be documented in this public README.

## Project Structure

```text
.
├── .schemas/
│   └── role.schema.json
├── modules/
│   └── role/
│       ├── main.tf
│       ├── outputs.tf
│       └── variables.tf
├── roles/
│   └── **/*.yml # Ignored by default and downloaded from S3
├── main.tf
├── outputs.tf
├── README.md
└── variables.tf
```

## Role Definition Shape

Role definitions follow `.schemas/role.schema.json`. At a high level, each definition includes:

- the role name;
- allowed GitHub repositories and references;
- the IAM condition matcher;
- IAM policy statements.

Production role definitions should avoid broad wildcards and should scope permissions to the minimum resources required.

## Local Validation

```bash
tofu fmt -check -recursive
tofu init
tofu validate
```
