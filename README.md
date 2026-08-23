# AWS Identity Provider for GitHub Actions

OpenTofu configuration for managing AWS Identity and Access Management (IAM) roles for GitHub Actions and AWS principal-based role assumption.

This repository defines:

- an AWS IAM OIDC provider for GitHub Actions;
- a reusable IAM role module for GitHub Actions federation and AWS principal trust;
- a schema for role definition files;
- root outputs for the managed role ARNs.

## Architecture

The root module creates the GitHub Actions OIDC provider and loads deployment-specific role definitions into the `modules/role` module. Each generated role uses either GitHub OIDC trust conditions or an AWS principal trust policy and attaches an IAM policy built from the role definition.

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

Role definitions follow `.schemas/role.schema.json`. Every file defines exactly one trust mechanism and includes an IAM permissions policy in `statements`.

Existing GitHub OIDC definitions remain unchanged. They include:

- the role name;
- allowed GitHub repositories and references;
- the IAM condition matcher;
- IAM policy statements.

AWS principal roles use an `assume_role` block instead of GitHub repository fields:

```yaml
name: Deployment
assume_role:
  principals:
    - arn:aws:iam::123456789012:role/AutomationGitHubRole
  conditions:
    - matcher: StringEquals
      variable: sts:ExternalId
      values:
        - deployment
statements:
  - sid: ReadCallerIdentity
    effect: Allow
    actions:
      - sts:GetCallerIdentity
    resources:
      - "*"
```

The caller must separately receive `sts:AssumeRole` permission for the target role through its own `statements`. Role relationships and caller permissions are not inferred automatically.

GitHub OIDC definitions create `<name>GitHubRole` and `<name>GitHubPolicy`. AWS principal definitions create `<name>Role` and `<name>Policy`.

Production role definitions should avoid broad wildcards and should scope permissions to the minimum resources required.

## Local Validation

```bash
tofu fmt -check -recursive
tofu init
tofu validate
tofu -chdir=modules/role init -backend=false
tofu -chdir=modules/role test
```
