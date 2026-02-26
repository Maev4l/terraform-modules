## ADDED Requirements

### Requirement: CORS variable

The module SHALL accept a `cors` variable that can be `null`, `false`, `true`, or an object.

#### Scenario: CORS disabled (default)
- **WHEN** `cors` is not set, `null`, or `false`
- **THEN** the API Gateway has no CORS configuration

#### Scenario: CORS enabled with permissive defaults
- **WHEN** `cors` is set to `true`
- **THEN** the API Gateway allows all origins, common methods, and common headers

#### Scenario: CORS enabled with custom config
- **WHEN** `cors` is set to an object with `allow_origins`
- **THEN** the API Gateway applies the custom CORS configuration

### Requirement: CORS configuration wiring

The module SHALL add a dynamic `cors_configuration` block to the `aws_apigatewayv2_api` resource when `cors` is not null.

#### Scenario: Configuration block created
- **WHEN** `cors` is set to a non-null value
- **THEN** the `aws_apigatewayv2_api` resource includes a `cors_configuration` block with the specified values

### Requirement: Optional fields with defaults

The module SHALL provide sensible defaults for optional CORS fields.

#### Scenario: Default methods
- **WHEN** `allow_methods` is not specified
- **THEN** it defaults to `["*"]` (all methods)

#### Scenario: Default headers
- **WHEN** `allow_headers` is not specified
- **THEN** it defaults to `["*"]` (all headers)
