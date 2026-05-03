# lambda-trigger-s3 — Implementation plan (frozen migration record)

> **Note:** Superpowers plans are normally written for upcoming work. This plan is a frozen record of work already completed, migrated from OpenSpec `tasks.md` files in the now-deleted `openspec/` tree. It is preserved for traceability and is **not intended to be executed** — the corresponding terraform module is already implemented and shipping.

## Tasks

### From change: lambda-modules

The tasks below are the trigger-s3-relevant subset of the `lambda-modules` OpenSpec change.

#### 5. Trigger module: lambda-trigger-s3

- [x] 5.1 Create `modules/lambda-trigger-s3/variables.tf` with: `function_name`, `function_arn`, `bucket_id`, `bucket_arn`, `events`, `filter_prefix`, `filter_suffix`, `tags`
- [x] 5.2 Create `modules/lambda-trigger-s3/main.tf` with `aws_s3_bucket_notification` and `aws_lambda_permission`
- [x] 5.3 Create `modules/lambda-trigger-s3/outputs.tf`
- [x] 5.4 Create `modules/lambda-trigger-s3/versions.tf` with required provider

> **Implementation note:** During implementation, `filter_prefix` and `filter_suffix` scalar variables (as specified in task 5.1) were superseded by a single `filters` variable of type `list(object({ prefix = optional(string), suffix = optional(string) }))`. This change was made because S3 only allows one `aws_s3_bucket_notification` resource per bucket; a list-based approach allows multiple independent filter combinations to be expressed within a single resource using a `dynamic "lambda_function"` block. The default value `[{}]` preserves the zero-config experience. The code is the source of truth.

#### 7. Examples (S3-relevant)

- [x] 7.3 Create `examples/multi-trigger/main.tf` — Lambda with multiple trigger types attached (includes S3 trigger)

#### 8. Validation (S3-relevant)

- [x] 8.1 Run `terraform fmt -recursive` on all modules (includes `lambda-trigger-s3`)
- [x] 8.2 Run `terraform validate` on each module (includes `lambda-trigger-s3`)
- [x] 8.3 Run `terraform validate` on each example (includes `examples/multi-trigger`)

## Verification performed

- `terraform fmt` (formatting check)
- `terraform validate` (provider schema validation)
- Manual usage in `examples/multi-trigger/` (S3 trigger wired as part of a multi-trigger composition)
