## Why

The lambda-function module lacks concurrency control. Users need to limit or guarantee Lambda capacity to prevent runaway costs, protect downstream services, or ensure dedicated execution capacity.

## What Changes

- Add `reserved_concurrent_executions` variable to lambda-function module
- Wire it to the `aws_lambda_function` resource
- Default to `null` (unreserved) to maintain backward compatibility

## Capabilities

### New Capabilities

- `reserved-concurrency`: Ability to set reserved concurrent executions on a Lambda function

### Modified Capabilities

(none)

## Impact

- `modules/lambda-function/variables.tf` - new variable
- `modules/lambda-function/main.tf` - wire to resource
- `modules/lambda-function/outputs.tf` - optionally expose configured value
