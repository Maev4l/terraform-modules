# lambda-trigger-s3 — Design

The `lambda-trigger-s3` module wires an existing S3 bucket to an existing Lambda function via S3 bucket notifications. It provisions the notification configuration on the bucket and the resource-based Lambda permission that allows S3 to invoke the function. Terraform practitioners use this module whenever an S3 bucket should push events (object creation, removal, etc.) to a Lambda function, with optional key-prefix and key-suffix filtering. The primary AWS services are Amazon S3 and AWS Lambda.

## Architecture

Resources created by this module:

- `aws_lambda_permission` — grants the S3 service (`s3.amazonaws.com`) permission to invoke the Lambda function, scoped to the specific bucket ARN
- `aws_s3_bucket_notification` — configures the bucket to invoke the Lambda function on the specified event types, with one `lambda_function` block per filter entry

One `aws_lambda_permission` is created per module invocation (one per bucket-function pair). One `lambda_function` block inside the `aws_s3_bucket_notification` is created per entry in the `filters` variable; the default `[{}]` produces a single unfiltered rule. S3 requires the Lambda permission to exist before it will accept the notification configuration, so the notification resource carries an explicit `depends_on` reference to the permission.

This module uses the resource-based IAM model (push-based trigger): no IAM role attachment is required. The Lambda execution role itself is managed separately, typically by `lambda-function`.

## Components

### aws_lambda_permission

Allows the S3 bucket to invoke the Lambda function. The statement ID is scoped to the function name (`AllowS3Invoke-<function_name>`) to avoid collisions when multiple S3 triggers are attached to the same function from different buckets. The `source_arn` is set to the bucket ARN, restricting the permission to events from that specific bucket only.

Key inputs:

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `function_name` | `string` | required | Used as part of the `statement_id` to make the permission unique per bucket-function pair |
| `function_arn` | `string` | required | Identifies the Lambda function to grant invocation rights on |
| `bucket_arn` | `string` | required | Scopes the permission to a single bucket; prevents confused-deputy issues |

### aws_s3_bucket_notification

Configures S3 to invoke the Lambda function when objects matching the specified criteria are created, removed, or otherwise modified. The resource uses a `dynamic "lambda_function"` block iterating over the `filters` variable, so multiple independent filter combinations can be expressed in a single notification resource (S3 only allows one `aws_s3_bucket_notification` resource per bucket).

Key inputs:

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `bucket_id` | `string` | required | The S3 bucket to configure notifications on |
| `events` | `list(string)` | required | S3 event types that trigger the Lambda (e.g. `["s3:ObjectCreated:*"]`); applied uniformly to all filter blocks |
| `filters` | `list(object({ prefix = optional(string), suffix = optional(string) }))` | `[{}]` | Each entry produces one `lambda_function` notification block; the default single empty object creates an unfiltered rule that matches all keys |
| `tags` | `map(string)` | `{}` | Accepted for interface consistency; neither S3 notifications nor Lambda permissions support tags, so the variable is a no-op |

Design decision — list-of-objects `filters` instead of scalar `filter_prefix`/`filter_suffix`: the original spec called for flat `filter_prefix` and `filter_suffix` variables. The implemented module instead uses a `filters` list. This allows a single module call to register multiple independent filter combinations (e.g. `.png` under `images/` and `.csv` under `data/`) without requiring multiple module invocations, which would conflict because S3 only permits one `aws_s3_bucket_notification` per bucket. The default `[{}]` preserves the zero-config path.

Outputs contributed:

| Output | Description |
|---|---|
| `notification_id` | The ID of the `aws_s3_bucket_notification` resource, useful for cross-module dependencies |

## Data flow

At runtime, when an S3 object event (e.g. a PUT that matches `s3:ObjectCreated:Put`) occurs on the configured bucket, S3 evaluates all active notification rules on the bucket. For each `lambda_function` block whose prefix and suffix filters match the object key, S3 invokes the Lambda function asynchronously, passing a JSON event payload that includes the bucket name, object key, event time, and event type.

The `depends_on` ordering ensures the Lambda permission is in place before the notification is created, preventing a race where S3 would attempt to send a test notification to a function it is not yet authorized to invoke.

## Error handling

Variable validations enforced by the module:

- None explicit — the module relies on Terraform type constraints (`list(string)` for `events`, `list(object(...))` for `filters`) to reject malformed inputs at plan time.

AWS-side guardrails:

- S3 enforces that only one `aws_s3_bucket_notification` resource may exist per bucket. Attempting to manage notifications from two separate Terraform states or modules targeting the same bucket will result in the second apply overwriting the first. This is an S3 API constraint, not something the module can prevent; it is documented as a known limitation.
- S3 validates that the event type strings are well-formed (e.g. `s3:ObjectCreated:*`); invalid event strings are rejected at the AWS API level during apply.
- The Lambda permission's `source_arn` scoping means that even if the S3 service principal is granted invoke access, only events from the specified bucket are accepted.

Known failure modes:

- If the bucket does not exist when the module is applied, the `aws_s3_bucket_notification` will fail with a `NoSuchBucket` error; the bucket must be created before or in the same `apply` with a proper dependency.
- If another Terraform resource or external configuration already manages notifications on the same bucket, applying this module will silently replace the existing notification configuration.

## Testing

Verification approach:

- `terraform fmt -check` run recursively across the module confirms formatting compliance
- `terraform validate` run against `modules/lambda-trigger-s3/` confirms provider schema validity
- The `examples/multi-trigger/` example exercises the S3 trigger module as part of a multi-trigger composition and can be validated with `terraform validate`
