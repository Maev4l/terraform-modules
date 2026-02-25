## ADDED Requirements

### Requirement: Lambda function creation
The module SHALL create an `aws_lambda_function` resource with user-provided function name, runtime, handler, and filename (local zip path).

#### Scenario: Minimal function creation
- **WHEN** the user provides `function_name`, `runtime`, `handler`, and `filename`
- **THEN** the module creates a Lambda function with those values and default settings for all other parameters

#### Scenario: Full configuration
- **WHEN** the user provides optional parameters (`memory_size`, `timeout`, `architecture`, `ephemeral_storage`, `layers`, `description`, `publish`)
- **THEN** the module applies those values to the Lambda function, overriding defaults

### Requirement: Default values
The module SHALL provide sane defaults for all optional Lambda function settings.

#### Scenario: Defaults applied when not overridden
- **WHEN** the user does not specify optional parameters
- **THEN** the module uses: `memory_size = 128`, `timeout = 3`, `architecture = "x86_64"`, `publish = false`

### Requirement: Environment variables
The module SHALL support passing environment variables to the Lambda function.

#### Scenario: Environment variables set
- **WHEN** the user provides an `environment_variables` map
- **THEN** the module configures the Lambda function's environment block with those key-value pairs

#### Scenario: No environment variables
- **WHEN** the user does not provide `environment_variables`
- **THEN** the module creates the Lambda function without an environment block

### Requirement: IAM execution role creation
The module SHALL create an IAM execution role for the Lambda function by default, with an assume role policy that allows the Lambda service to assume it.

#### Scenario: Default role creation
- **WHEN** `existing_role_arn` is not provided (null)
- **THEN** the module creates an `aws_iam_role` with a trust policy for `lambda.amazonaws.com` and assigns it to the Lambda function

#### Scenario: BYO role
- **WHEN** `existing_role_arn` is provided
- **THEN** the module does not create an IAM role and assigns the provided ARN to the Lambda function

### Requirement: CloudWatch Logs policy
The module SHALL attach a CloudWatch Logs IAM policy to the Lambda's execution role, allowing it to create log streams and put log events.

#### Scenario: Log policy on created role
- **WHEN** the module creates the execution role (`existing_role_arn` is null)
- **THEN** the module attaches a policy granting `logs:CreateLogGroup`, `logs:CreateLogStream`, and `logs:PutLogEvents` to the role

#### Scenario: Log policy on BYO role with attach_log_policy true
- **WHEN** `existing_role_arn` is provided and `attach_log_policy` is true (default)
- **THEN** the module attaches the CloudWatch Logs policy to the provided role

#### Scenario: Log policy on BYO role with attach_log_policy false
- **WHEN** `existing_role_arn` is provided and `attach_log_policy` is false
- **THEN** the module does not attach any IAM policy to the provided role

### Requirement: CloudWatch Log Group
The module SHALL create a CloudWatch Log Group for the Lambda function with a configurable retention period.

#### Scenario: Log group creation
- **WHEN** the module creates a Lambda function
- **THEN** it creates an `aws_cloudwatch_log_group` named `/aws/lambda/{function_name}` with a default retention of 14 days

#### Scenario: Custom retention
- **WHEN** the user provides `log_retention_in_days`
- **THEN** the module uses that value for the log group retention period

### Requirement: VPC configuration
The module SHALL optionally place the Lambda function inside a VPC.

#### Scenario: VPC enabled
- **WHEN** the user provides `subnet_ids` and `security_group_ids`
- **THEN** the module configures the Lambda function's `vpc_config` block with those values and attaches the `AWSLambdaVPCAccessExecutionRole` managed policy to the execution role

#### Scenario: No VPC
- **WHEN** the user does not provide `subnet_ids` and `security_group_ids`
- **THEN** the module creates the Lambda function without VPC configuration

### Requirement: Tags
The module SHALL accept a `tags` map and apply it to all resources created by the module.

#### Scenario: Tags propagation
- **WHEN** the user provides a `tags` map
- **THEN** the module applies those tags to the Lambda function, IAM role (if created), and CloudWatch Log Group

#### Scenario: No tags
- **WHEN** the user does not provide tags
- **THEN** resources are created without additional tags

### Requirement: Module outputs
The module SHALL expose outputs required by trigger modules and for general use.

#### Scenario: Outputs available
- **WHEN** the module creates a Lambda function
- **THEN** it outputs: `function_name`, `function_arn`, `invoke_arn`, `role_name` (if created), `role_arn`, `log_group_name`
