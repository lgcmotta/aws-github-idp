# AWS Identity Provider - GitHub

This project provides a GitHub Actions integration with AWS using an OpenID Connect (OIDC) Identity Provider. It dynamically creates AWS IAM roles that can be assumed by GitHub Actions workflows based on YAML configuration files with custom JSON schema validation.

## Overview

The solution eliminates the need for long-lived AWS credentials in GitHub Actions by using short-lived tokens through OIDC federation. Each role is defined in YAML files and automatically provisioned with specific permissions for specific repositories, branches, tags, and environments.

## Architecture

- **OIDC Provider**: Establishes trust between GitHub Actions and AWS
- **Dynamic Role Creation**: Automatically creates IAM roles from YAML definitions
- **Schema Validation**: Ensures role configurations follow the defined JSON schema
- **Granular Access Control**: Supports repository, branch, tag, and environment-based access patterns

## Prerequisites

- OpenTofu >= 1.9
- AWS CLI configured with appropriate permissions
- GitHub Actions (OIDC provider URL: `https://token.actions.githubusercontent.com`)

## Project Structure

```
├── .schemas/
│   └── role.schema.json          # JSON schema for role validation
├── modules/
│   └── role/                     # Role module for creating IAM roles
├── roles/
│   ├── infrastructure/           # Infrastructure-related roles
│   │   ├── aws/                 # AWS service-specific roles
│   │   ├── backstage/           # Backstage platform roles
│   │   ├── datadog/             # DataDog monitoring roles
│   │   └── ...
│   └── microservices/           # Application-specific roles
│       ├── pop/                 # POP frontend roles
│       └── portal/              # Portal frontend roles
├── main.tf                      # Main configuration
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
└── backend.tf                   # S3 backend configuration
```

## Role Configuration Schema

Each role is defined in a YAML file following this schema:

```yaml
name: "RoleName"                 # Required: Role identifier
repositories:                    # Required: GitHub repositories (OWNER/REPO)
  - "my-user/my-repo"
matcher: "StringLike"            # Required: Condition matcher type
branches:                        # Optional: Allowed branches (default: [])
  - "main"
  - "develop"
tags:                           # Optional: Allowed tags (default: [])
  - "v*"
environments:                   # Optional: GitHub Environments (use when workflow sets `environment`)
  - "development"
statements:                     # Required: IAM policy statements
  - sid: "StatementId"
    effect: "Allow"
    actions:
      - "service:Action"
    resources:
      - "arn:aws:service:::resource"
    conditions:                 # Optional: Additional conditions
      - matcher: "StringEquals"
        variable: "aws:RequestedRegion"
        values: ["us-east-1"]
```
## Security Features

- **Temporary Credentials**: No long-lived access keys
- **Repository-based Access**: Roles tied to specific GitHub repositories
- **Branch/Tag Restrictions**: Fine-grained access control
- **Least Privilege**: Minimal required permissions per role
- **Audit Trail**: All actions logged through CloudTrail

## Outputs

The module provides:

- `github_assume_role_arns`: List of all created role ARNs for GitHub Actions configuration

## Schema Validation

Role definitions are validated against `.schemas/role.schema.json` which enforces:

- Required fields (name, repositories, matcher, statements)
- Valid IAM action patterns
- Proper condition structure
- Statement format compliance

## Best Practices

1. **Minimal Permissions**: Grant only necessary permissions
2. **Repository Isolation**: Use separate roles for different repositories
3. **Branch Protection**: Restrict production access to main branches
4. **Resource Scoping**: Limit access to specific resources when possible
5. **Regular Audits**: Review and update permissions periodically
