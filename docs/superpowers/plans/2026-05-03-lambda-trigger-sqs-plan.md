# lambda-trigger-sqs — Implementation plan (frozen migration record)

> **Note:** Superpowers plans are normally written for upcoming work. This plan is a frozen record of work already completed, migrated from OpenSpec `tasks.md` files in the now-deleted `openspec/` tree. It is preserved for traceability and is **not intended to be executed** — the corresponding terraform module is already implemented and shipping.

## Tasks

### From change: trigger-sqs

## 1. Create SQS trigger module

- [x] 1.1 Create `modules/lambda-trigger-sqs/variables.tf` with: `function_name`, `function_arn`, `role_name`, `queue_arn`, `batch_size`, `maximum_batching_window_in_seconds`, `report_batch_item_failures`, `filter_criteria`, `tags`
- [x] 1.2 Create `modules/lambda-trigger-sqs/main.tf` with `aws_lambda_event_source_mapping` (batch config, optional filter criteria, optional function response types), `aws_iam_policy` and `aws_iam_role_policy_attachment` for SQS read permissions
- [x] 1.3 Create `modules/lambda-trigger-sqs/outputs.tf` exposing `event_source_mapping_id`
- [x] 1.4 Create `modules/lambda-trigger-sqs/versions.tf` with required provider

## 2. Documentation

- [x] 2.1 Create `modules/lambda-trigger-sqs/README.md` with exhaustive input/output documentation

## 3. Example

- [x] 3.1 Create `examples/sqs/main.tf` — Lambda triggered by SQS queue with batch config, partial failure reporting, and filter criteria

## 4. Validation

- [x] 4.1 Run `terraform fmt -recursive` on new files

## Verification performed

- `terraform fmt` (formatting check)
- `terraform validate` (provider schema validation)
- Manual usage in `examples/sqs/` (applicable — example provided)
