## Why

SNS is one of the most common event sources for Lambda functions — used for fan-out patterns, decoupled microservices, and notification processing. The module suite currently supports API Gateway, DynamoDB streams, S3, and Cognito triggers but is missing SNS. Adding it completes the core set of push-based triggers.

## What Changes

- **New trigger module (`lambda-trigger-sns`)**: Creates an SNS topic subscription pointing to a Lambda function, with a resource-based policy allowing SNS to invoke the Lambda. Optionally supports SNS subscription filter policies for message filtering.

## Capabilities

### New Capabilities

- `trigger-sns`: SNS topic subscription trigger with optional filter policy, Lambda invocation permission, and tags support.

### Modified Capabilities

None.

## Impact

- **New Terraform module**: `modules/lambda-trigger-sns/`
- **New example**: `examples/sns/main.tf`
- **AWS services touched**: SNS, Lambda (permission)
- **IAM model**: Push-based (resource-based policy via `aws_lambda_permission`) — no `role_name` needed
