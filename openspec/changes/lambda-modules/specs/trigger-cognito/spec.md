## ADDED Requirements

### Requirement: Cognito User Pool trigger wiring
The module SHALL configure a Lambda function as a trigger on a Cognito User Pool for specified trigger types.

#### Scenario: Single trigger type
- **WHEN** the user provides `function_name`, `function_arn`, `user_pool_id`, and `triggers = ["pre_sign_up"]`
- **THEN** the module configures the Cognito User Pool's `lambda_config` to invoke the Lambda function for the `pre_sign_up` trigger

#### Scenario: Multiple trigger types
- **WHEN** the user provides `triggers = ["pre_sign_up", "post_confirmation", "pre_token_generation"]`
- **THEN** the module configures the Cognito User Pool's `lambda_config` to invoke the Lambda function for all three trigger types, all pointing to the same Lambda function

### Requirement: Supported trigger types
The module SHALL accept a list of strings for the `triggers` variable. Supported values are: `pre_sign_up`, `post_confirmation`, `pre_authentication`, `post_authentication`, `pre_token_generation`, `custom_message`, `define_auth_challenge`, `create_auth_challenge`, `verify_auth_challenge_response`, `user_migration`.

#### Scenario: All trigger types accepted
- **WHEN** the user specifies any of the supported trigger type strings in the `triggers` list
- **THEN** the module configures the corresponding Cognito lambda_config attribute

### Requirement: Lambda invocation permission
The module SHALL create a resource-based policy allowing the Cognito User Pool to invoke the Lambda function.

#### Scenario: Permission created
- **WHEN** the module configures Cognito triggers
- **THEN** it creates an `aws_lambda_permission` allowing the Cognito service (`cognito-idp.amazonaws.com`) to invoke the Lambda function, scoped to the provided `user_pool_id`

### Requirement: Tags
The module SHALL accept a `tags` map for interface consistency.

#### Scenario: Tags accepted
- **WHEN** the user provides a `tags` map
- **THEN** the module accepts the variable without error
