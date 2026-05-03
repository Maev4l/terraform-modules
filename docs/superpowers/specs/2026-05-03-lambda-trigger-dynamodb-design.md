# lambda-trigger-dynamodb — Design

This module wires a DynamoDB stream to an AWS Lambda function via an event source mapping. It is the correct choice when a Terraform practitioner wants to invoke a Lambda in response to DynamoDB item-level changes, with control over batch size, starting position, parallel shard processing, and optional record filtering. The module also manages the IAM policy that grants the Lambda's execution role permission to read from the stream — no separate IAM work is required from the caller.

## Architecture

AWS resources created by this module:

- `aws_lambda_event_source_mapping` — polls the DynamoDB stream and invokes the Lambda in batches
- `aws_iam_policy` — inline policy document granting DynamoDB stream read permissions
- `aws_iam_role_policy_attachment` — attaches the policy to the Lambda's execution role

The event source mapping is the central resource. It references both the stream ARN (source) and the Lambda function ARN (target). The IAM policy is named `<function_name>-dynamodb-stream-read` and scoped to the exact stream ARN provided, following least-privilege. The event source mapping explicitly `depends_on` the policy attachment so that AWS never attempts to activate the trigger before the execution role has the required permissions.

## Components

### aws_lambda_event_source_mapping

The event source mapping is what AWS uses to poll the DynamoDB stream and batch records for delivery to the Lambda. Key inputs:

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `function_arn` | `string` | required | ARN of the Lambda to invoke |
| `stream_arn` | `string` | required | ARN of the DynamoDB stream to read from |
| `starting_position` | `string` | `"LATEST"` | Where in the stream to begin reading (`LATEST` or `TRIM_HORIZON`) |
| `batch_size` | `number` | `100` | Maximum records per Lambda invocation |
| `maximum_batching_window_in_seconds` | `number` | `0` | How long AWS waits to fill a batch before invoking; `0` means invoke as soon as records are available |
| `parallelization_factor` | `number` | `1` | Number of concurrent batches per shard; increasing this allows a single shard to drive multiple parallel Lambda invocations |
| `filter_criteria` | `list(object({ pattern = string }))` | `[]` | Optional list of filter patterns; when provided, only matching records reach the Lambda |

The `filter_criteria` block is rendered conditionally: when the list is empty the block is omitted entirely (no filtering applied), and when at least one pattern is provided a `filter_criteria { filter { pattern = ... } }` block is constructed for each entry. This avoids emitting an empty `filter_criteria {}` block, which AWS would reject.

Output contributed: `event_source_mapping_id` — the UUID of the mapping, useful for referencing or importing the resource.

### aws_iam_policy / aws_iam_role_policy_attachment

The IAM policy grants the four actions required for Lambda to consume a DynamoDB stream:

- `dynamodb:GetRecords`
- `dynamodb:GetShardIterator`
- `dynamodb:DescribeStream`
- `dynamodb:ListStreams`

The resource scope is pinned to `var.stream_arn`, not `*`.

**Design decision — trigger modules manage their own IAM:** The module accepts `role_name` (the name of the Lambda's execution role) and attaches the stream read policy itself. Pushing IAM attachment to the caller would defeat the "one-stop shop" goal of the lambda-modules design: the trigger module knows exactly which permissions it needs, and asking the practitioner to figure this out and wire it separately is unnecessary friction (from `openspec/changes/lambda-modules/design.md`).

Key inputs driving this component:

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `function_name` | `string` | required | Used to name the IAM policy (`<function_name>-dynamodb-stream-read`) |
| `role_name` | `string` | required | The execution role to attach the policy to |
| `tags` | `map(string)` | `{}` | Tags applied to the `aws_iam_policy` resource |

## Data flow

At runtime, DynamoDB writes change records to the stream for every item-level mutation (INSERT, MODIFY, REMOVE). AWS polls the stream on behalf of the event source mapping and accumulates records up to `batch_size` or until `maximum_batching_window_in_seconds` elapses. If `filter_criteria` is configured, AWS evaluates each record against the patterns before batching; non-matching records are discarded without invoking the Lambda.

Once the batch is ready, the Lambda's execution role (with the attached stream read policy) is used to call `GetRecords` and retrieve the payload, which is then delivered synchronously to the Lambda function. When `parallelization_factor` is greater than `1`, multiple batches from the same shard can be in-flight concurrently.

## Error handling

Variable validations enforced by the module:

- None explicit in `.tf` files — the module relies on Terraform type constraints (`string`, `number`, `list(object(...))`) to reject malformed inputs at plan time.

AWS-side guardrails:

- The stream ARN must exist and the DynamoDB stream must be enabled; AWS will reject the event source mapping creation otherwise.
- `starting_position` must be `LATEST` or `TRIM_HORIZON`; any other value is rejected by the AWS API at apply time.
- `parallelization_factor` must be between 1 and 10; values outside this range are rejected by the AWS API.
- `batch_size` for DynamoDB streams must be between 1 and 10,000; AWS enforces this limit.

The `depends_on` from `aws_lambda_event_source_mapping` to `aws_iam_role_policy_attachment.stream_read` prevents a race where the mapping is activated before the role has stream read permissions, which would cause immediate trigger failures.

## Testing

- `terraform fmt -check -recursive` run against the module to verify formatting.
- `terraform validate` run against the module directory to verify provider schema compliance.
- The module is exercised indirectly via the `examples/multi-trigger/main.tf` example, which combines multiple trigger modules against a single Lambda function.
