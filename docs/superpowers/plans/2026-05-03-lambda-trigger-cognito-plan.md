# lambda-trigger-cognito — Implementation plan (frozen migration record)

> **Note:** Superpowers plans are normally written for upcoming work. This plan is a frozen record of work already completed, migrated from OpenSpec `tasks.md` files in the now-deleted `openspec/` tree. It is preserved for traceability and is **not intended to be executed** — the corresponding terraform module is already implemented and shipping.

## Tasks

### From change: lambda-modules

The following tasks are the trigger-cognito-relevant subset of the full `lambda-modules` change.

**6. Trigger module: lambda-trigger-cognito**

- [x] 6.1 Create `modules/lambda-trigger-cognito/variables.tf` with: `function_name`, `function_arn`, `user_pool_id`, `triggers` (list of strings), `tags`
- [x] 6.2 Create `modules/lambda-trigger-cognito/main.tf` with `aws_cognito_user_pool_lambda_config` (or equivalent) wiring each trigger type to the Lambda, and `aws_lambda_permission`
- [x] 6.3 Create `modules/lambda-trigger-cognito/outputs.tf`
- [x] 6.4 Create `modules/lambda-trigger-cognito/versions.tf` with required provider

**8. Validation (cognito module)**

- [x] 8.1 Run `terraform fmt -recursive` on all modules
- [x] 8.2 Run `terraform validate` on each module
- [x] 8.3 Run `terraform validate` on each example

## Verification performed

- `terraform fmt` (formatting check)
- `terraform validate` (provider schema validation)
- Manual usage in `examples/` (if applicable)
