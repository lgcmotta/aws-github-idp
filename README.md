# AWS Identity Provider for GitHub Actions

OpenTofu configuration for managing AWS Identity and Access Management (IAM) roles for GitHub Actions and AWS principal-based role assumption.

This repository defines:

- an AWS IAM OIDC provider for GitHub Actions;
- a reusable IAM role module for GitHub Actions federation and AWS principal trust;
- a reusable application user module that creates credentials and an assumable role;
- schemas for role and user definition files;
- root outputs for ARNs, application credentials, and the AWS region.

## Architecture

The root module creates the GitHub Actions OIDC provider and loads deployment-specific role definitions into the `modules/role` module. Each generated role uses either GitHub OIDC trust conditions or an AWS principal trust policy and attaches one customer-managed IAM policy for each named policy group in the role definition.

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

Role definitions follow `.schemas/role.schema.json`. Every file defines exactly one trust mechanism and includes named IAM permission groups in `policies`. Every group requires a `name` and a nonempty `statements` list; the map key identifies the group in OpenTofu state.

GitHub OIDC trust fields remain unchanged. Role definitions include:

- the role name;
- allowed GitHub repositories and references;
- the IAM condition matcher;
- named groups of IAM policy statements.

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
policies:
  identity:
    name: Identity
    statements:
      - sid: ReadCallerIdentity
        effect: Allow
        actions:
          - sts:GetCallerIdentity
        resources:
          - "*"
```

The caller must separately receive `sts:AssumeRole` permission for the target role through a statement in one of its own policy groups. Role relationships and caller permissions are not inferred automatically.

GitHub OIDC definitions create `<name>GitHubRole` and `<name>GitHub<group.name>Policy`. AWS principal definitions create `<name>Role` and `<name><group.name>Policy`. For example, a group named `Storage` on `MarekVetInfrastructure` produces `MarekVetInfrastructureGitHubStoragePolicy`.

Group names must be unique within a role, ignoring case. The module validates generated names against the 128-character IAM limit and each compact policy document against the 6,144-character limit. It accepts up to 20 groups per role, matching the current default AWS attachment quota; account quotas and attachments managed elsewhere must also be considered. Statements and their conditions stay together within a group. Changing a map key changes the OpenTofu resource address; changing a group name replaces the AWS policy.

The former top-level `statements` format is no longer supported. Every role definition must migrate to `policies`.

Production role definitions should avoid broad wildcards and should scope permissions to the minimum resources required.

## Local Validation

```bash
tofu fmt -check -recursive
tofu init
tofu validate
```

## Application users

The root loads `users/**/*.yml` into `modules/user`. Each definition creates one IAM user, one access key, and one application role. The user receives an inline policy allowing only `sts:AssumeRole` on its application role. The role trusts that user, and `modules/role` attaches the named runtime policy groups to the role. No console login is created.

User definitions follow `.schemas/user.schema.json` and use the same `policies` shape as role definitions:

```yaml
name: ExampleBackendProduction
policies:
  signing:
    name: Signing
    statements:
      - sid: SignMessages
        effect: Allow
        actions:
          - kms:Sign
        resources:
          - arn:aws:kms:us-east-1:123456789012:key/REPLACE_WITH_KEY_ID
```

For this example, the module creates `ExampleBackendProductionApplicationUser`, `ExampleBackendProductionApplicationRole`, and `ExampleBackendProductionApplicationSigningPolicy`. The base name must fit within 49 characters so the generated user and role names fit IAM's limits. The map keys identify policy groups in OpenTofu state, and each group's `name` determines its managed-policy name.

The `users/` directory currently contains only `.keep`. No application users, access keys, or roles are requested until a YAML definition is added. User definitions are Git-ignored, like role definitions; do not put credentials into YAML.

For GitHub Actions, configure the `AWS_S3_USERS_BUCKET_URI` secret with the S3 location of user definitions. The workflow downloads these separately from role definitions and skips the download when that secret is unset. Keep the secret configured after provisioning users so future runs receive the complete definitions. The deployment role needs read access to the chosen S3 location. The local `roles/github.yml` includes permissions to manage `*ApplicationUser`, `*ApplicationRole`, and `*Application*Policy` resources. Upload its updated definition and apply those permissions before introducing any user definitions.

### Railway outputs

Root outputs are keyed by the user YAML filename without `.yml`, with directory separators replaced by underscores. For a future `users/backend.yml`:

| Railway setting | Root output |
| --- | --- |
| `AWS_ACCESS_KEY_ID` | `user_credentials["backend"].AWS_ACCESS_KEY_ID` (sensitive) |
| `AWS_SECRET_ACCESS_KEY` | `user_credentials["backend"].AWS_SECRET_ACCESS_KEY` (sensitive) |
| `AWS_ROLE_ARN` | `user_role_arns["backend"]` |
| `AWS_REGION` | `aws_region` |

`user_arns["backend"]` exposes the IAM user ARN separately and is not sensitive. `aws_region` uses the root `aws.region` setting; set it to the region containing the application resources.

After an authorized apply, read individual values locally:

```bash
tofu output -json user_credentials | jq -r '.backend.AWS_ACCESS_KEY_ID'
tofu output -json user_credentials | jq -r '.backend.AWS_SECRET_ACCESS_KEY'
tofu output -json user_role_arns | jq -r '.backend'
tofu output -raw aws_region
tofu output -json user_arns | jq -r '.backend'
```

Sensitive marking hides credentials from ordinary plan/apply output. Explicit `tofu output -json` reveals them, and the access-key secret is stored in OpenTofu state. Keep state and output access restricted; do not run credential-output commands in CI logs. See the [AWS provider access-key documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key).

The backend authenticates with the user key, then uses an STS assume-role credential provider to obtain and refresh temporary credentials for `AWS_ROLE_ARN`. Configure the SDK explicitly to use that provider; an `AWS_ROLE_ARN` environment variable alone does not universally enable this flow. KMS key policies must also authorize the role or enable IAM delegation; this module does not modify KMS keys.
