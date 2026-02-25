## 1. Project scaffolding

- [x] 1.1 Create directory structure: `modules/lambda-function/`, `modules/lambda-trigger-apigw/`, `modules/lambda-trigger-dynamodb/`, `modules/lambda-trigger-s3/`, `modules/lambda-trigger-cognito/`, `examples/`
- [x] 1.2 Create root `versions.tf` with required AWS provider constraint

## 2. Core module: lambda-function

- [x] 2.1 Create `modules/lambda-function/variables.tf` with all input variables: `function_name`, `runtime`, `handler`, `filename`, `memory_size`, `timeout`, `architecture`, `ephemeral_storage`, `layers`, `description`, `publish`, `environment_variables`, `existing_role_arn`, `attach_log_policy`, `log_retention_in_days`, `subnet_ids`, `security_group_ids`, `tags`
- [x] 2.2 Create `modules/lambda-function/main.tf` with `aws_lambda_function`, `aws_cloudwatch_log_group`
- [x] 2.3 Create `modules/lambda-function/iam.tf` with conditional `aws_iam_role`, `aws_iam_role_policy_attachment` for CloudWatch Logs, conditional VPC execution role policy, and `attach_log_policy` logic for BYO roles
- [x] 2.4 Create `modules/lambda-function/outputs.tf` exposing `function_name`, `function_arn`, `invoke_arn`, `role_name`, `role_arn`, `log_group_name`
- [x] 2.5 Create `modules/lambda-function/versions.tf` with required provider

## 3. Trigger module: lambda-trigger-apigw

- [x] 3.1 Create `modules/lambda-trigger-apigw/variables.tf` with: `function_name`, `function_arn`, `invoke_arn`, `routes`, `stage_name`, `custom_domain`, `tags`
- [x] 3.2 Create `modules/lambda-trigger-apigw/main.tf` with `aws_apigatewayv2_api`, `aws_apigatewayv2_stage`, `aws_apigatewayv2_integration`, `aws_apigatewayv2_route` (for_each on routes), `aws_lambda_permission`
- [x] 3.3 Create `modules/lambda-trigger-apigw/domain.tf` with conditional `aws_apigatewayv2_domain_name`, `aws_apigatewayv2_api_mapping`, `aws_route53_record` (A alias) — created only when `custom_domain` is not null
- [x] 3.4 Create `modules/lambda-trigger-apigw/outputs.tf` exposing `api_id`, `api_endpoint`, `execution_arn`, `stage_id`, `custom_domain_url`
- [x] 3.5 Create `modules/lambda-trigger-apigw/versions.tf` with required provider

## 4. Trigger module: lambda-trigger-dynamodb

- [x] 4.1 Create `modules/lambda-trigger-dynamodb/variables.tf` with: `function_name`, `function_arn`, `role_name`, `stream_arn`, `starting_position`, `batch_size`, `maximum_batching_window_in_seconds`, `parallelization_factor`, `filter_criteria`, `tags`
- [x] 4.2 Create `modules/lambda-trigger-dynamodb/main.tf` with `aws_lambda_event_source_mapping` including optional filter criteria
- [x] 4.3 Create `modules/lambda-trigger-dynamodb/iam.tf` with `aws_iam_policy` and `aws_iam_role_policy_attachment` granting DynamoDB stream read permissions to the Lambda execution role
- [x] 4.4 Create `modules/lambda-trigger-dynamodb/outputs.tf` exposing `event_source_mapping_id`
- [x] 4.5 Create `modules/lambda-trigger-dynamodb/versions.tf` with required provider

## 5. Trigger module: lambda-trigger-s3

- [x] 5.1 Create `modules/lambda-trigger-s3/variables.tf` with: `function_name`, `function_arn`, `bucket_id`, `bucket_arn`, `events`, `filter_prefix`, `filter_suffix`, `tags`
- [x] 5.2 Create `modules/lambda-trigger-s3/main.tf` with `aws_s3_bucket_notification` and `aws_lambda_permission`
- [x] 5.3 Create `modules/lambda-trigger-s3/outputs.tf`
- [x] 5.4 Create `modules/lambda-trigger-s3/versions.tf` with required provider

## 6. Trigger module: lambda-trigger-cognito

- [x] 6.1 Create `modules/lambda-trigger-cognito/variables.tf` with: `function_name`, `function_arn`, `user_pool_id`, `triggers` (list of strings), `tags`
- [x] 6.2 Create `modules/lambda-trigger-cognito/main.tf` with `aws_cognito_user_pool_lambda_config` (or equivalent) wiring each trigger type to the Lambda, and `aws_lambda_permission`
- [x] 6.3 Create `modules/lambda-trigger-cognito/outputs.tf`
- [x] 6.4 Create `modules/lambda-trigger-cognito/versions.tf` with required provider

## 7. Examples

- [x] 7.1 Create `examples/simple/main.tf` — minimal Lambda with no triggers
- [x] 7.2 Create `examples/api-gateway/main.tf` — Lambda with HTTP API and custom domain
- [x] 7.3 Create `examples/multi-trigger/main.tf` — Lambda with multiple trigger types attached

## 8. Validation

- [x] 8.1 Run `terraform fmt -recursive` on all modules
- [ ] 8.2 Run `terraform validate` on each module (blocked: provider dev override prevents terraform init)
- [ ] 8.3 Run `terraform validate` on each example (blocked: provider dev override prevents terraform init)
