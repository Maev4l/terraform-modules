## Why

The API Gateway trigger module currently creates unauthenticated HTTP APIs. Most production APIs require authorization — typically JWT validation against a Cognito User Pool or another OIDC provider. Without authorizer support, users must manage `aws_apigatewayv2_authorizer` resources outside the module, breaking the one-stop-shop pattern.

## What Changes

- **Add optional `authorizer` object variable** to the `lambda-trigger-apigw` module, following the same pattern as `custom_domain` (null by default, all-or-nothing when provided)
- **Create `aws_apigatewayv2_authorizer` resource** when the `authorizer` object is provided, supporting JWT authorizer type (covers Cognito, Auth0, Okta, and any OIDC provider)
- **Wire authorizer to all routes** — when an authorizer is configured, all routes use it
- **Add Cognito example** showing the full flow: User Pool + API Gateway with JWT authorizer

## Capabilities

### New Capabilities

None — this extends the existing `trigger-apigw` capability.

### Modified Capabilities

- `trigger-apigw`: Adds optional JWT authorizer support via an `authorizer` object variable, creating an `aws_apigatewayv2_authorizer` and applying it to all routes.

## Impact

- **Modified files**: `modules/lambda-trigger-apigw/variables.tf`, `modules/lambda-trigger-apigw/main.tf`, `modules/lambda-trigger-apigw/outputs.tf`
- **New example**: `examples/api-gateway-cognito/main.tf`
- **No new modules or breaking changes**: Existing usage without `authorizer` is unaffected
