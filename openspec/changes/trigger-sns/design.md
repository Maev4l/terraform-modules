## Context

The module suite has four trigger modules. SNS follows the same push-based pattern as S3 and Cognito — SNS invokes the Lambda, so IAM is handled via a resource-based policy (`aws_lambda_permission`), not the execution role.

The module creates two resources: an `aws_sns_topic_subscription` (protocol: lambda) and an `aws_lambda_permission`. Optionally, a subscription filter policy can narrow which messages reach the Lambda.

## Goals / Non-Goals

**Goals:**

- Create an SNS trigger module following existing patterns (push-based, no `role_name`)
- Support optional subscription filter policy for message filtering
- Consistent interface: `function_name`, `function_arn`, `topic_arn`, `tags`

**Non-Goals:**

- SNS topic creation — the topic must already exist (BYO)
- Dead letter queue configuration on the subscription
- Raw message delivery toggle (can be added later)

## Decisions

### Module resources

The module creates exactly two resources (plus optional filter):

```
aws_sns_topic_subscription  — protocol "lambda", endpoint = function_arn
aws_lambda_permission       — allow sns.amazonaws.com to invoke the function
```

**Rationale:** Minimal, focused. Matches the S3 and Cognito trigger pattern.

### Filter policy as a JSON string

The `filter_policy` variable accepts a JSON-encoded string rather than a structured object. SNS filter policies have flexible schemas (string matching, numeric matching, prefix matching, etc.) that don't map cleanly to a Terraform type constraint.

```hcl
filter_policy = jsonencode({
  event_type = ["order_placed", "order_shipped"]
})
```

**Rationale:** Keeps the variable simple while supporting the full SNS filter policy syntax. The user is responsible for valid JSON — same pattern used by the DynamoDB trigger's `filter_criteria`.

### No role_name needed

SNS is push-based. SNS sends messages to Lambda via an invocation, not a poll. The Lambda permission (`aws_lambda_permission`) is the only IAM resource needed.

## Risks / Trade-offs

**[Filter policy validation is runtime-only]** → Terraform cannot validate the filter policy JSON structure at plan time. Invalid filter policies will fail at apply time when AWS rejects them. This is acceptable — same limitation exists across all Terraform resources that accept JSON policy documents.
