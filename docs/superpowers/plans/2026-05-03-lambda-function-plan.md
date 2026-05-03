# lambda-function — Implementation plan (frozen migration record)

> **Note:** Superpowers plans are normally written for upcoming work. This plan is a frozen record of work already completed, migrated from OpenSpec `tasks.md` files in the now-deleted `openspec/` tree. It is preserved for traceability and is **not intended to be executed** — the corresponding terraform module is already implemented and shipping.

## Tasks

### From change: lambda-modules

The following tasks are the lambda-core-relevant subset of the original `lambda-modules` change. Trigger-module tasks (sections 3–7) are preserved in their respective trigger-module plans.

## 1. Project scaffolding

- [x] 1.1 Create directory structure: `modules/lambda-function/`, `modules/lambda-trigger-apigw/`, `modules/lambda-trigger-dynamodb/`, `modules/lambda-trigger-s3/`, `modules/lambda-trigger-cognito/`, `examples/`
- [x] 1.2 Create root `versions.tf` with required AWS provider constraint

## 2. Core module: lambda-function

- [x] 2.1 Create `modules/lambda-function/variables.tf` with all input variables: `function_name`, `runtime`, `handler`, `filename`, `memory_size`, `timeout`, `architecture`, `ephemeral_storage`, `layers`, `description`, `publish`, `environment_variables`, `existing_role_arn`, `attach_log_policy`, `log_retention_in_days`, `subnet_ids`, `security_group_ids`, `tags`
- [x] 2.2 Create `modules/lambda-function/main.tf` with `aws_lambda_function`, `aws_cloudwatch_log_group`
- [x] 2.3 Create `modules/lambda-function/iam.tf` with conditional `aws_iam_role`, `aws_iam_role_policy_attachment` for CloudWatch Logs, conditional VPC execution role policy, and `attach_log_policy` logic for BYO roles
- [x] 2.4 Create `modules/lambda-function/outputs.tf` exposing `function_name`, `function_arn`, `invoke_arn`, `role_name`, `role_arn`, `log_group_name`
- [x] 2.5 Create `modules/lambda-function/versions.tf` with required provider

## 7. Examples

- [x] 7.1 Create `examples/simple/main.tf` — minimal Lambda with no triggers
- [x] 7.2 Create `examples/api-gateway/main.tf` — Lambda with HTTP API and custom domain
- [x] 7.3 Create `examples/multi-trigger/main.tf` — Lambda with multiple trigger types attached

## 8. Validation

- [x] 8.1 Run `terraform fmt -recursive` on all modules
- [x] 8.2 Run `terraform validate` on each module
- [x] 8.3 Run `terraform validate` on each example

### From change: lambda-container-image-support

## 1. Restructure packaging variables

- [x] 1.1 Replace `filename`, `runtime`, `handler` variables with `zip` object variable (type: `object({ filename = string, runtime = string, handler = string })`, default: `null`) in `modules/lambda-function/variables.tf`
- [x] 1.2 Add `image` object variable (type: `object({ uri = string, command = optional(list(string)), entry_point = optional(list(string)), working_directory = optional(string) })`, default: `null`) in `modules/lambda-function/variables.tf`
- [x] 1.3 Add validation block ensuring exactly one of `zip` or `image` is non-null

## 2. Update core module main.tf

- [x] 2.1 Add locals for packaging mode: `is_zip = var.zip != null`, `is_image = var.image != null`, `has_image_config` for override detection
- [x] 2.2 Update `aws_lambda_function` resource: add `package_type`, make `filename`/`runtime`/`handler`/`source_code_hash` conditional on zip mode, add `image_uri` conditional on image mode
- [x] 2.3 Add dynamic `image_config` block for container image overrides (command, entry_point, working_directory)
- [x] 2.4 Make `layers` conditional on zip mode (set to `[]` in image mode)

## 3. Update examples

- [x] 3.1 Update `examples/simple/main.tf` to use `zip = { ... }` block
- [x] 3.2 Update `examples/api-gateway/main.tf` to use `zip = { ... }` block
- [x] 3.3 Update `examples/multi-trigger/main.tf` to use `zip = { ... }` block

## 4. Validation

- [x] 4.1 Run `terraform fmt -recursive` on all modified files

### From change: lambda-reserved-concurrency

## 1. Add variable

- [x] 1.1 Add `reserved_concurrent_executions` variable to `modules/lambda-function/variables.tf` (type: number, default: null)

## 2. Wire to resource

- [x] 2.1 Add `reserved_concurrent_executions = var.reserved_concurrent_executions` to `aws_lambda_function` resource in `modules/lambda-function/main.tf`

## 3. Validation

- [x] 3.1 Run `terraform fmt` on the module
- [x] 3.2 Run `terraform validate` on the module

## Verification performed

- `terraform fmt` (formatting check)
- `terraform validate` (provider schema validation)
- Manual usage in `examples/simple/`, `examples/container-image/`, `examples/api-gateway/`, `examples/multi-trigger/`
