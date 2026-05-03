# lambda-trigger-sns — Design

The `lambda-trigger-sns` module wires an existing SNS topic to a Lambda function by creating a topic subscription and the resource-based policy that allows SNS to invoke the function. It is the right choice whenever a Lambda must receive messages published to an SNS topic — for fan-out patterns, decoupled microservices, or notification processing. Because SNS is push-based (SNS calls Lambda, not the other way around), no execution-role changes are required; IAM is handled entirely through the Lambda resource policy.

## Architecture

Resources created by the module:

- `aws_lambda_permission` — resource-based policy statement granting `sns.amazonaws.com` the right to invoke the function, scoped to the specific topic ARN
- `aws_sns_topic_subscription` — SNS subscription with `protocol = "lambda"` that delivers messages to the function ARN; optionally constrained by a filter policy

The permission is created first (`depends_on` ensures ordering). When a message is published to the topic, SNS evaluates any configured filter policy before invoking the Lambda. With no filter policy, every message is delivered; with one, only matching messages reach the function.

## Components

### aws_lambda_permission

Grants `sns.amazonaws.com` the `lambda:InvokeFunction` action on the target function, with `source_arn` set to the topic ARN so the permission is scoped to that specific topic rather than all SNS topics. The `statement_id` is derived from `var.function_name` to keep it human-readable and unique within the function's policy.

Key inputs:

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `function_name` | `string` | required | Provides the unique `statement_id` suffix (`AllowSNSInvoke-<function_name>`) |
| `function_arn` | `string` | required | ARN used as the `function_name` argument on the permission resource |
| `topic_arn` | `string` | required | Limits the permission to invocations from this topic (`source_arn`) |

This resource produces no module-level outputs.

### aws_sns_topic_subscription

Creates an SNS subscription with `protocol = "lambda"` and `endpoint` set to the Lambda ARN. The subscription is created after the Lambda permission so that SNS can confirm the subscription immediately (subscription confirmation requires the invocation permission to already be in place).

Key inputs:

| Variable | Type | Default | Purpose |
|---|---|---|---|
| `function_arn` | `string` | required | Set as the subscription `endpoint` |
| `topic_arn` | `string` | required | Identifies the SNS topic to subscribe to |
| `filter_policy` | `string` | `null` | JSON-encoded SNS filter policy; `null` means no filtering (all messages delivered) |
| `filter_policy_scope` | `string` | `"MessageAttributes"` | Controls whether filtering applies to message attributes or the message body (`MessageBody`); only set on the subscription when `filter_policy` is non-null |
| `tags` | `map(string)` | `{}` | Accepted for interface consistency; not applied to the subscription resource (SNS subscriptions do not support tags via Terraform) |

Design decision — `filter_policy` as a JSON string: SNS filter policies support a flexible, multi-type syntax (string matching, numeric ranges, prefix matching, etc.) that cannot be expressed with a single Terraform type constraint. Accepting a pre-encoded JSON string keeps the variable surface minimal while supporting the full SNS filter policy syntax. The user is responsible for providing valid JSON; invalid documents are rejected by AWS at apply time.

Design decision — `filter_policy_scope` only set when `filter_policy` is non-null: Setting `filter_policy_scope` on a subscription with no filter policy is a no-op at the AWS level but generates unnecessary diffs. The expression `var.filter_policy != null ? var.filter_policy_scope : null` avoids this.

Key output:

| Output | Source | Purpose |
|---|---|---|
| `subscription_arn` | `aws_sns_topic_subscription.this.arn` | ARN of the created subscription, useful for downstream automation or monitoring |

## Data flow

A publisher calls `sns:Publish` on the topic. SNS fans out the message to all confirmed subscribers. For this module's subscription, SNS first evaluates the filter policy (if set): messages whose attributes or body do not match the policy are silently dropped; matching messages (or all messages when no filter is set) are forwarded to Lambda via a synchronous invocation using the `lambda:InvokeFunction` API. The Lambda permission authorizes this invocation, scoped to the exact topic ARN.

The Lambda receives the event as a standard SNS event envelope containing one or more `Records`, each with the `Sns` key holding the message body and attributes. The function's response is not returned to the publisher; SNS does not wait for it (fire-and-forget from the publisher's perspective).

## Error handling

Variable validations enforced by the module:

- No `validation { }` blocks are defined in `variables.tf`. Required variables (`function_name`, `function_arn`, `topic_arn`) are enforced by Terraform's type system — a missing value will cause a plan-time error.

AWS-side guardrails:

- The SNS topic identified by `topic_arn` must already exist. Terraform will surface an AWS API error at apply time if the topic does not exist.
- The Lambda function identified by `function_arn` must already exist. SNS subscription confirmation and the Lambda permission creation both require the function to be present.
- An invalid `filter_policy` JSON document is rejected by the AWS SNS API at apply time with a descriptive error message. There is no plan-time validation of the policy content.

Known failure modes:

- **Missing `aws_lambda_permission` race**: Without the `depends_on` ordering, SNS may attempt to confirm the subscription before the permission exists. The module addresses this by explicitly ordering the permission before the subscription.
- **Stale filter policy scope**: If `filter_policy` is later removed (set to `null`) without also unsetting `filter_policy_scope`, the module's conditional expression returns `null` for the scope, which correctly removes it from the subscription.

## Testing

Verification approach:

- `terraform fmt -check` on all files under `modules/lambda-trigger-sns/`
- `terraform validate` against the module directory (requires provider initialization)
- Usage example: `examples/sns/main.tf` — demonstrates a Lambda subscribed to an SNS topic with an `event_type` filter policy
