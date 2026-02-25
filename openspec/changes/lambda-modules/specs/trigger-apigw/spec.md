## ADDED Requirements

### Requirement: HTTP API creation
The module SHALL create an AWS API Gateway HTTP API (v2) that integrates with a single Lambda function.

#### Scenario: API created
- **WHEN** the user provides `function_name`, `function_arn`, and `invoke_arn`
- **THEN** the module creates an `aws_apigatewayv2_api` with protocol type `HTTP`

### Requirement: Lambda integration
The module SHALL create a Lambda proxy integration on the HTTP API.

#### Scenario: Integration created
- **WHEN** the HTTP API is created
- **THEN** the module creates an `aws_apigatewayv2_integration` with integration type `AWS_PROXY` and the provided `invoke_arn` as the integration target

### Requirement: Route configuration
The module SHALL create one route per entry in the `routes` variable, all pointing to the same Lambda integration.

#### Scenario: Single route
- **WHEN** the user provides `routes = ["GET /users"]`
- **THEN** the module creates one `aws_apigatewayv2_route` with route key `GET /users` targeting the Lambda integration

#### Scenario: Multiple routes
- **WHEN** the user provides `routes = ["GET /orders", "POST /orders", "GET /orders/{id}", "DELETE /orders/{id}"]`
- **THEN** the module creates four `aws_apigatewayv2_route` resources, each targeting the same Lambda integration

### Requirement: Stage
The module SHALL create an API Gateway stage with a configurable name.

#### Scenario: Default stage
- **WHEN** the user does not provide `stage_name`
- **THEN** the module creates an `aws_apigatewayv2_stage` named `$default` with auto-deploy enabled

#### Scenario: Custom stage name
- **WHEN** the user provides `stage_name`
- **THEN** the module creates a stage with that name and auto-deploy enabled

### Requirement: Lambda invocation permission
The module SHALL create a resource-based policy allowing the API Gateway to invoke the Lambda function.

#### Scenario: Permission created
- **WHEN** the HTTP API and routes are created
- **THEN** the module creates an `aws_lambda_permission` allowing the API Gateway execution ARN to invoke the Lambda function

### Requirement: Custom domain
The module SHALL optionally configure a custom domain name with Route53 DNS when the `custom_domain` object is provided.

#### Scenario: Custom domain configured
- **WHEN** the user provides a `custom_domain` object with `domain_name`, `hosted_zone_id`, and `certificate_arn`
- **THEN** the module creates an `aws_apigatewayv2_domain_name` with the provided certificate, an `aws_apigatewayv2_api_mapping` linking the domain to the stage, and an `aws_route53_record` (A alias) pointing the domain to the API Gateway domain

#### Scenario: No custom domain
- **WHEN** the user does not provide `custom_domain` (null)
- **THEN** the module does not create any domain, mapping, or Route53 resources

### Requirement: Tags
The module SHALL accept a `tags` map and apply it to all resources created by the module.

#### Scenario: Tags propagation
- **WHEN** the user provides a `tags` map
- **THEN** the module applies those tags to the HTTP API, stage, and domain name (if created)

### Requirement: Module outputs
The module SHALL expose outputs for the API endpoint and optionally the custom domain URL.

#### Scenario: Outputs available
- **WHEN** the module creates an HTTP API
- **THEN** it outputs: `api_id`, `api_endpoint` (the default API Gateway URL), `execution_arn`, `stage_id`

#### Scenario: Custom domain outputs
- **WHEN** a custom domain is configured
- **THEN** the module additionally outputs: `custom_domain_url`
