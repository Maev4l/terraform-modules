## Why

APIs called from browsers need CORS (Cross-Origin Resource Sharing) configuration to allow cross-origin requests. Currently the module has no way to configure CORS, forcing users to handle it manually in Lambda code or modify the API outside Terraform.

## What Changes

- Add `cors` variable to lambda-trigger-apigw module
- Add dynamic `cors_configuration` block to `aws_apigatewayv2_api` resource
- Default to `null` (CORS disabled)

## Capabilities

### New Capabilities

- `apigw-cors`: Ability to configure CORS for API Gateway HTTP APIs

### Modified Capabilities

(none)

## Impact

- `modules/lambda-trigger-apigw/variables.tf` - new variable
- `modules/lambda-trigger-apigw/main.tf` - add dynamic cors_configuration block
