# lambda-trigger-dynamodb — Implementation plan (frozen migration record)

> **Note:** Superpowers plans are normally written for upcoming work. This plan is a frozen record of work already completed, migrated from OpenSpec `tasks.md` files in the now-deleted `openspec/` tree. It is preserved for traceability and is **not intended to be executed** — the corresponding terraform module is already implemented and shipping.

## Tasks

### From change: lambda-modules

## 4. Trigger module: lambda-trigger-dynamodb

- [x] 4.1 Create `modules/lambda-trigger-dynamodb/variables.tf` with: `function_name`, `function_arn`, `role_name`, `stream_arn`, `starting_position`, `batch_size`, `maximum_batching_window_in_seconds`, `parallelization_factor`, `filter_criteria`, `tags`
- [x] 4.2 Create `modules/lambda-trigger-dynamodb/main.tf` with `aws_lambda_event_source_mapping` including optional filter criteria
- [x] 4.3 Create `modules/lambda-trigger-dynamodb/iam.tf` with `aws_iam_policy` and `aws_iam_role_policy_attachment` granting DynamoDB stream read permissions to the Lambda execution role
- [x] 4.4 Create `modules/lambda-trigger-dynamodb/outputs.tf` exposing `event_source_mapping_id`
- [x] 4.5 Create `modules/lambda-trigger-dynamodb/versions.tf` with required provider

## Verification performed

- `terraform fmt` (formatting check)
- `terraform validate` (provider schema validation)
- Manual usage in `examples/` (if applicable)
