## Why

When using a custom domain with API Gateway, the default execute endpoint (`https://{api-id}.execute-api.{region}.amazonaws.com`) remains accessible. Users need to disable it to enforce traffic through their custom domain only, improving security and simplifying access control.

## What Changes

- Add `disable_execute_api_endpoint` variable to lambda-trigger-apigw module
- Wire it to the `aws_apigatewayv2_api` resource
- Default to `true` (disabled) for security by default

## Capabilities

### New Capabilities

- `disable-default-endpoint`: Ability to disable the default API Gateway execute endpoint

### Modified Capabilities

(none)

## Impact

- `modules/lambda-trigger-apigw/variables.tf` - new variable
- `modules/lambda-trigger-apigw/main.tf` - wire to resource
