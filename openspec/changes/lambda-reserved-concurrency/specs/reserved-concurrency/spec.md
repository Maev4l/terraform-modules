## ADDED Requirements

### Requirement: Reserved concurrency variable

The module SHALL accept a `reserved_concurrent_executions` variable of type `number` with default `null`.

#### Scenario: Default behavior (unreserved)
- **WHEN** `reserved_concurrent_executions` is not set or set to `null`
- **THEN** the Lambda function uses unreserved concurrency from the account pool

#### Scenario: Reserved concurrency set
- **WHEN** `reserved_concurrent_executions` is set to a positive integer (e.g., `10`)
- **THEN** the Lambda function reserves that number of concurrent executions

#### Scenario: Throttled function
- **WHEN** `reserved_concurrent_executions` is set to `0`
- **THEN** the Lambda function cannot execute (fully throttled)

### Requirement: Resource attribute wiring

The module SHALL pass the `reserved_concurrent_executions` variable to the `aws_lambda_function` resource's `reserved_concurrent_executions` attribute.

#### Scenario: Attribute applied
- **WHEN** `reserved_concurrent_executions` is set to any non-null value
- **THEN** the `aws_lambda_function` resource has `reserved_concurrent_executions` set to that value

#### Scenario: Attribute omitted
- **WHEN** `reserved_concurrent_executions` is `null`
- **THEN** the `aws_lambda_function` resource does not set `reserved_concurrent_executions`
