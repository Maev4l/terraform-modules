# lambda-function EFS Support — Design

Adds optional Amazon EFS mount support to the `lambda-function` module so a Lambda (zip or container image) can mount an EFS access point at a `/mnt/...` path. This lets functions read and write a shared, persistent POSIX filesystem — for example a SQLite database or large working files that must outlive a single invocation. Practitioners should set the new `efs_config` variable whenever a function needs durable, file-based state that EFS provides.

This capability was driven by the `alamut` project (self-hosted Vaultwarden on Lambda), which stores its SQLite database on EFS.

## Architecture

The feature adds **one optional input variable** (`efs_config`) and, when it is set, two things:

- A `file_system_config` block on the existing `aws_lambda_function` resource (it must be declared *inside* the function resource — it cannot be attached externally).
- A least-privilege EFS-client IAM policy attached to the module's execution role, scoped to the supplied access point.

No new module is created; this extends the existing `lambda-function` module. EFS access requires VPC networking, so the module enforces that VPC inputs are present whenever `efs_config` is set. A new `has_efs = var.efs_config != null` local gates both the `file_system_config` block and the IAM resources (mirroring the existing `has_vpc` pattern).

## Components

### efs_config variable

A single optional object variable, defaulting to `null` (feature off).

| Field | Type | Purpose |
|---|---|---|
| `access_point_arn` | `string` | ARN of the EFS access point to mount. Drives both the `file_system_config.arn` attribute and the IAM policy scope. |
| `local_mount_path` | `string` | Path where the file system is mounted in the function. Must start with `/mnt` (AWS requirement). |

The variable carries a `validation` block enforcing that `local_mount_path` starts with `/mnt`, so misconfiguration fails at plan time rather than apply time.

**Why an access point (not a raw file system):** mounting via an EFS access point lets the file system enforce a POSIX identity and a root directory for the function, which is the recommended pattern for Lambda + EFS. The module takes only the access point ARN; the caller owns the access point, file system, and mount targets.

### file_system_config block

A `dynamic "file_system_config"` block on `aws_lambda_function`, rendered only when `has_efs` is true:

- `arn` = `var.efs_config.access_point_arn`
- `local_mount_path` = `var.efs_config.local_mount_path`

### VPC precondition

A second `precondition` is added to the existing `lifecycle` block on `aws_lambda_function`:

- Condition: `!local.has_efs || local.has_vpc`
- Message: `"efs_config requires VPC configuration (both subnet_ids and security_group_ids must be set)."`

This catches the most common misconfiguration — requesting an EFS mount without placing the function in a VPC — which AWS would otherwise reject more obscurely at apply time.

### EFS-client IAM policy

When `has_efs` is true, the module creates (all `count`-gated, mirroring the existing `vpc`/`additional` attachments):

- `aws_iam_policy_document.efs` — grants `elasticfilesystem:ClientMount` and `elasticfilesystem:ClientWrite`, with `resources = ["*"]` constrained by a `StringEquals` condition on `elasticfilesystem:AccessPointArn = var.efs_config.access_point_arn`.
- `aws_iam_policy.efs` named `<function_name>-efs`.
- `aws_iam_role_policy_attachment.efs` binding it to the execution role.

**Why `resources = ["*"]` with an access-point condition:** EFS client actions target the file system resource, but the module only receives the access point ARN (the file-system ID cannot be derived from it). The `elasticfilesystem:AccessPointArn` condition scopes the grant to exactly the supplied access point, achieving least privilege without requiring an additional file-system-ARN input. `ClientRootAccess` is intentionally omitted — the access point enforces the POSIX identity, so root access is not needed for the common case.

## Data flow

At deploy time, the caller provides an EFS access point ARN and a `/mnt` mount path together with VPC subnets and security groups. The module renders the `file_system_config` block and attaches the EFS-client policy to the function's execution role. At invocation time, the Lambda runtime mounts the access point at the configured path; the function reads and writes the EFS filesystem under the access point's enforced POSIX identity and root directory, using the IAM permissions granted by the attached policy.

Mount-target readiness is a deploy-time ordering concern: AWS requires the EFS mount targets in the function's subnets to exist before the function is created. The module receives only an ARN string, so it cannot infer this dependency — the caller must declare `depends_on = [aws_efs_mount_target.<name>]` on the module call (demonstrated in `examples/efs/`).

## Error handling

Validations enforced by the module:

- **Mount-path validation** (variable `validation`): `local_mount_path` must start with `/mnt`, else plan fails with `"efs_config.local_mount_path must start with /mnt (AWS Lambda requirement)."`
- **VPC precondition** (`lifecycle.precondition`): `efs_config` set without VPC inputs aborts with `"efs_config requires VPC configuration (both subnet_ids and security_group_ids must be set)."`

AWS-side guardrails relied upon:

- AWS rejects creation of a Lambda with `file_system_config` whose mount targets are not yet available in the function's subnets (mitigated by caller `depends_on`).
- AWS validates the access point ARN at apply time.

Known failure modes:

- **Missing `depends_on` on mount targets:** without it, the first apply can race and fail because the mount target is not ready. Mitigated by documenting the requirement and showing it in the example.
- **POSIX permission mismatch:** if the access point's `posix_user`/`creation_info` does not match what the function process expects, reads/writes can fail with permission errors. This is the caller's responsibility (access point configuration), not the module's.

## Testing

- `terraform fmt -check` on all files under `modules/lambda-function/`
- `terraform validate` against `modules/lambda-function/` (requires provider initialization)
- Example usage under `examples/efs/` — VPC + EFS file system, mount target, and access point wired into the module with `efs_config` and `depends_on`
