## ADDED Requirements

### Requirement: Disable execute API endpoint variable

The module SHALL accept a `disable_execute_api_endpoint` variable of type `bool` with default `true`.

#### Scenario: Default behavior (endpoint disabled)
- **WHEN** `disable_execute_api_endpoint` is not set or set to `true`
- **THEN** the API Gateway default execute endpoint returns 403 Forbidden

#### Scenario: Endpoint enabled
- **WHEN** `disable_execute_api_endpoint` is set to `false`
- **THEN** the API Gateway default execute endpoint is accessible

### Requirement: Resource attribute wiring

The module SHALL pass the `disable_execute_api_endpoint` variable to the `aws_apigatewayv2_api` resource's `disable_execute_api_endpoint` attribute.

#### Scenario: Attribute applied
- **WHEN** `disable_execute_api_endpoint` is `true`
- **THEN** the `aws_apigatewayv2_api` resource has `disable_execute_api_endpoint = true`
