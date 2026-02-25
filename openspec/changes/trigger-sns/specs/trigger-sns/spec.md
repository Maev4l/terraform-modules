## ADDED Requirements

### Requirement: SNS topic subscription
The module SHALL create an SNS topic subscription that delivers messages to a Lambda function.

#### Scenario: Subscription created
- **WHEN** the user provides `function_name`, `function_arn`, and `topic_arn`
- **THEN** the module creates an `aws_sns_topic_subscription` with protocol `lambda` and endpoint set to the provided `function_arn`

### Requirement: Lambda invocation permission
The module SHALL create a resource-based policy allowing the SNS topic to invoke the Lambda function.

#### Scenario: Permission created
- **WHEN** the module creates the topic subscription
- **THEN** it creates an `aws_lambda_permission` allowing the SNS service (`sns.amazonaws.com`) to invoke the Lambda function, scoped to the provided `topic_arn`

### Requirement: Subscription filter policy
The module SHALL optionally support an SNS subscription filter policy to deliver only matching messages to the Lambda function.

#### Scenario: Filter policy provided
- **WHEN** the user provides `filter_policy` as a JSON-encoded string
- **THEN** the module configures the subscription's `filter_policy` attribute with the provided value

#### Scenario: No filter policy
- **WHEN** the user does not provide `filter_policy` (null)
- **THEN** the module creates the subscription without filtering (all messages are delivered)

### Requirement: Filter policy scope
The module SHALL support configuring the filter policy scope to apply filtering on message attributes or message body.

#### Scenario: Default filter policy scope
- **WHEN** the user provides `filter_policy` but does not provide `filter_policy_scope`
- **THEN** the module uses `MessageAttributes` as the default scope

#### Scenario: Custom filter policy scope
- **WHEN** the user provides `filter_policy_scope` (e.g., `MessageBody`)
- **THEN** the module applies that scope to the subscription

### Requirement: Tags
The module SHALL accept a `tags` map for interface consistency.

#### Scenario: Tags accepted
- **WHEN** the user provides a `tags` map
- **THEN** the module accepts the variable without error

### Requirement: Module outputs
The module SHALL expose outputs for the subscription.

#### Scenario: Outputs available
- **WHEN** the module creates the subscription
- **THEN** it outputs: `subscription_arn`
