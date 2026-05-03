# lambda-function — Design

The `lambda-function` module provisions a complete AWS Lambda execution environment from a single Terraform call. It creates the Lambda function itself, a dedicated IAM execution role with logging and optional VPC policies, and a CloudWatch Log Group — everything a function needs to run and emit logs without additional IAM wiring. Practitioners should use this module whenever they need to deploy a Lambda function from either a local zip archive or a pre-built ECR container image.

## Architecture

Resources created by the module:

- `aws_lambda_function` — the Lambda function itself
- `aws_iam_role` — execution role with a Lambda service trust policy
- `aws_iam_policy` — inline CloudWatch Logs policy scoped to the function's log group
- `aws_iam_role_policy_attachment` (logs) — binds the logs policy to the execution role
- `aws_iam_role_policy_attachment` (vpc, count-based) — attaches `AWSLambdaVPCAccessExecutionRole` when VPC is enabled; zero instances when not
- `aws_iam_role_policy_attachment` (additional, count-based) — one per entry in `additional_policy_arns`; zero instances when the list is empty
- `aws_cloudwatch_log_group` — pre-created log group at `/aws/lambda/<function_name>`

The module creates exactly one IAM execution role per function. The log group is created before the function (via `depends_on`) so the function never races against CloudWatch for log group ownership. VPC placement and additional managed policies are optional and controlled entirely through input variables.

## Components

### aws_lambda_function

The Lambda function resource. It supports two mutually exclusive packaging modes — zip and container image — selected by providing either the `zip` or `image` variable (exactly one must be non-null, enforced by a `lifecycle.precondition`).

Key inputs:

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `function_name` | `string` | required | Function name and prefix for all sibling resources |
| `zip` | `object({ filename, runtime, handler, hash? })` | `null` | Zip packaging: local file path, runtime identifier, handler string. Optional `hash` for pre-computed `source_code_hash`; computed from the file if omitted. |
| `image` | `object({ uri, command?, entry_point?, working_directory? })` | `null` | Container image packaging: ECR image URI plus optional `image_config` overrides. |
| `memory_size` | `number` | `128` | MB of memory allocated to the function |
| `timeout` | `number` | `3` | Execution timeout in seconds |
| `architecture` | `string` | `"x86_64"` | Instruction set architecture (`x86_64` or `arm64`) |
| `ephemeral_storage` | `number` | `512` | `/tmp` directory size in MB (512–10240) |
| `layers` | `list(string)` | `[]` | Lambda Layer ARNs; silently ignored in container image mode (AWS limitation) |
| `publish` | `bool` | `false` | Whether to publish a numbered version on deploy |
| `environment_variables` | `map(string)` | `{}` | Environment variables; omitted from the resource when the map is empty |
| `reserved_concurrent_executions` | `number` | `null` | Reserved concurrency: `null` = unreserved pool, `0` = fully throttled, `1+` = reserved slots |
| `description` | `string` | `null` | Optional human-readable description |
| `subnet_ids` | `list(string)` | `[]` | VPC subnet IDs; non-empty list enables VPC placement |
| `security_group_ids` | `list(string)` | `[]` | VPC security group IDs; non-empty list enables VPC placement |
| `tags` | `map(string)` | `{}` | Tags applied to all resources |

**Packaging mode decision:** The `zip` and `image` variables are mutually exclusive objects (each defaulting to `null`) rather than a flat set of top-level variables. This groups packaging-related fields by mode, makes the exactly-one constraint expressible as a single precondition, and mirrors the pattern used by the API Gateway trigger module's `custom_domain` variable.

**Container image digest pinning:** When using `image` mode, the `uri` field should reference a digest (`repo@sha256:…`) rather than a mutable tag. Lambda resolves a tag to a digest at update time and caches it — pushing a new image to `:latest` produces no Terraform diff and the new image never rolls out. Using a digest ensures every image change is visible to Terraform.

**Source code hash for zip:** In zip mode, `source_code_hash` is set to `filebase64sha256(var.zip.filename)` by default. The optional `zip.hash` field allows callers to supply a pre-computed hash (useful in CI pipelines where the zip is built in a separate step and the hash is known ahead of time).

### IAM role and policies

The module always creates an IAM execution role named `<function_name>-execution-role` with a trust policy allowing `lambda.amazonaws.com` to assume it.

Key inputs:

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `additional_policy_arns` | `list(string)` | `[]` | Managed policy ARNs to attach to the execution role beyond the baseline log policy |

A custom IAM policy named `<function_name>-logs` is always created, granting `logs:CreateLogStream` and `logs:PutLogEvents` scoped to the function's log group ARN and its log streams. This policy is always attached to the execution role.

When `subnet_ids` and `security_group_ids` are both non-empty (`has_vpc = true`), the AWS-managed `AWSLambdaVPCAccessExecutionRole` policy is attached via a count-based `aws_iam_role_policy_attachment`. This policy grants the ENI management permissions Lambda requires to operate inside a VPC.

**BYO-role removal:** An earlier design iteration included `existing_role_arn` and `attach_log_policy` variables to support bringing your own IAM role. These were removed from the implementation. The module always creates its own role. Callers needing to attach additional policies should use `additional_policy_arns`.

### aws_cloudwatch_log_group

Pre-creates the log group at the conventional path `/aws/lambda/<function_name>` so that log retention is enforced from the first invocation. The `aws_lambda_function` resource declares a `depends_on` on this resource.

Key inputs:

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `log_retention_in_days` | `number` | `7` | CloudWatch log retention period |

Output: `log_group_name` — the full `/aws/lambda/<function_name>` path.

### Reserved concurrency

`reserved_concurrent_executions` is wired directly to the `aws_lambda_function` attribute of the same name. When `null` (default), the attribute is omitted and the function draws from the account-level unreserved concurrency pool. Setting it to `0` fully throttles the function; any positive integer reserves that many execution slots from the account pool.

## Data flow

At invocation time, a caller (API Gateway, event source, or direct invoke) triggers the Lambda function. The function executes under the permissions of its IAM execution role — write access to its specific log group is always present; VPC ENI permissions are present when VPC is configured; any additional permissions come from `additional_policy_arns`. Execution logs are streamed to the pre-created CloudWatch Log Group automatically by the Lambda runtime.

For zip-packaged functions, code changes are detected by `source_code_hash` (computed from the local file or provided explicitly). For container-image functions, code changes are detected by a change in `image_uri` — when the URI includes a digest, every new image push changes the digest, triggers a Terraform diff, and causes Lambda to pull the new image on next invocation.

## Error handling

Variable validations enforced by the module:

- **Packaging mode precondition** (`lifecycle.precondition` on `aws_lambda_function`): exactly one of `zip` or `image` must be non-null. If both are `null` or both are set, Terraform aborts with: `"Exactly one of 'zip' or 'image' must be provided."`

AWS-side guardrails relied upon:

- Lambda rejects `image_uri` values that point to non-existent or inaccessible ECR images at apply time.
- Lambda rejects container images built with OCI media types or attestation manifests (requires Docker v2 schema 2 — use `--provenance=false --sbom=false` with `docker buildx build`).
- `reserved_concurrent_executions` is validated by AWS at apply time against the account's available concurrency limit; there is no upper-bound validation in the module (the limit varies per account and region).
- `ephemeral_storage` below 512 MB or above 10 240 MB will be rejected by the AWS provider.

Known failure modes:

- **Mutable image tag with no digest:** If `image.uri` uses a mutable tag (e.g., `:latest`), pushing a new image to ECR produces no Terraform diff and the function is never updated. Mitigated by using digest-pinned URIs.
- **`layers` silently dropped in image mode:** Supplying `layers` with an `image` configuration does not error; the module sets `layers = []` in image mode. Users sharing a variable set across functions should be aware of this silent no-op.

## Testing

- `terraform fmt -check` on all files under `modules/lambda-function/`
- `terraform validate` against `modules/lambda-function/` (requires provider initialization)
- Example usage under `examples/simple/` (zip packaging, minimal configuration)
- Example usage under `examples/container-image/` (container image packaging with environment variables and arm64 architecture)
- Example usage under `examples/api-gateway/` (Lambda with HTTP API Gateway trigger)
