# lambda-trigger-scheduler — Design

Provides a reusable Terraform module that wires an AWS EventBridge Scheduler schedule to an existing Lambda function. The module creates the schedule, a dedicated IAM execution role scoped to the scheduler service principal, and optionally an inline policy for a dead-letter SQS queue. Supported expression types are `rate(…)`, `cron(…)`, and `at(…)` for one-time invocations.

## Architecture

The module composes three AWS resource types:

- `aws_scheduler_schedule` — the EventBridge Scheduler schedule (in a named or default group).
- `aws_iam_role` + `aws_iam_role_policy` — a scheduler-specific IAM role with least-privilege `lambda:InvokeFunction` permission, and an optional `sqs:SendMessage` policy for dead-letter routing.

No `aws_lambda_permission` is created; EventBridge Scheduler relies on the IAM role rather than resource-based Lambda permissions.

Data sources used:
- `aws_caller_identity` — account ID injected into the IAM assume-role condition to prevent confused deputy attacks.
- `aws_region` — available for future use (not referenced in current resources).

## Components

### aws_scheduler_schedule

The core schedule resource. Controlled by:

| Variable | Type | Default | Notes |
|---|---|---|---|
| `schedule_name` | `string` | required | Name of the schedule; also used in the IAM role name. |
| `schedule_expression` | `string` | required | `rate(…)`, `cron(…)`, or `at(…)` expression. |
| `function_arn` | `string` | required | ARN of the target Lambda function. |
| `function_name` | `string` | required | Name of the Lambda function (used for resource naming). |
| `schedule_group_name` | `string` | `"default"` | EventBridge Scheduler schedule group. |
| `description` | `string` | `null` | Human-readable description. |
| `timezone` | `string` | `"UTC"` | IANA timezone for cron/rate expressions. |
| `flexible_time_window` | `number` | `0` | Minutes of allowed jitter; `0` → mode `OFF` (exact time). |
| `start_date` | `string` | `null` | ISO 8601 activation date. |
| `end_date` | `string` | `null` | ISO 8601 deactivation date. |
| `enabled` | `bool` | `true` | Maps to schedule state `ENABLED`/`DISABLED`. |
| `input` | `string` | `null` | JSON payload forwarded to the Lambda invocation. |
| `retry_policy` | `object` | `null` | Optional: `maximum_event_age_in_seconds` (default 86400) and `maximum_retry_attempts` (default 185). |
| `dead_letter_arn` | `string` | `null` | SQS queue ARN for failed-invocation dead-lettering. |
| `kms_key_arn` | `string` | `null` | KMS key ARN to encrypt the schedule payload at rest. |

### aws_iam_role (scheduler)

A dedicated role named `scheduler-<schedule_name>-role`, assumable only by `scheduler.amazonaws.com` with a `StringEquals` condition on `aws:SourceAccount`. This prevents cross-account confused deputy issues.

Tags are passed through via `var.tags`.

### aws_iam_role_policy (invoke + dead-letter)

Two inline policies on the scheduler role:

- `invoke-lambda` — always created; grants `lambda:InvokeFunction` on `var.function_arn`.
- `dead-letter-queue` — created only when `var.dead_letter_arn != null`; grants `sqs:SendMessage` on that queue ARN.

## Data flow

1. EventBridge Scheduler evaluates the schedule expression in the configured `timezone`.
2. At fire time, the service assumes `aws_iam_role.scheduler` (bound to the caller's account).
3. The assumed role grants `lambda:InvokeFunction` on the target function ARN.
4. The Lambda function is invoked synchronously by the scheduler; any JSON `input` is forwarded as the event payload.
5. On invocation failure and after exhausting the optional `retry_policy`, EventBridge Scheduler routes the event to the dead-letter SQS queue (if `dead_letter_arn` is set).

## Error handling

- **Schedule expression validity** — not validated in Terraform; AWS rejects invalid `rate`, `cron`, or `at` expressions at apply time.
- **Cron format** — EventBridge Scheduler cron syntax requires a 6-field expression (including year); standard Unix 5-field crons are not accepted and will error at the AWS API level.
- **Dead-letter routing** — if `dead_letter_arn` is set, the scheduler role automatically receives `sqs:SendMessage`; forgetting to create the SQS queue beforehand will cause an AWS validation error at apply time.
- **KMS encryption** — if `kms_key_arn` is provided, the caller must ensure the scheduler service principal has `kms:GenerateDataKey` and `kms:Decrypt` access on that key; this module does not create the KMS key policy.
- **Flexible time window** — setting `flexible_time_window > 0` changes mode to `FLEXIBLE`; AWS enforces the maximum window is between 1 and 1440 minutes.

## Testing

- `terraform fmt -check` — formatting conformance.
- `terraform validate` — provider schema validation (requires AWS provider initialization).
- No dedicated `examples/` directory is present in this module at the time of writing.
