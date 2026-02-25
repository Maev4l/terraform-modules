## 1. Create SNS trigger module

- [x] 1.1 Create `modules/lambda-trigger-sns/variables.tf` with: `function_name`, `function_arn`, `topic_arn`, `filter_policy`, `filter_policy_scope`, `tags`
- [x] 1.2 Create `modules/lambda-trigger-sns/main.tf` with `aws_sns_topic_subscription` (protocol lambda) and `aws_lambda_permission`, optional filter policy and filter policy scope
- [x] 1.3 Create `modules/lambda-trigger-sns/outputs.tf` exposing `subscription_arn`
- [x] 1.4 Create `modules/lambda-trigger-sns/versions.tf` with required provider

## 2. Example

- [x] 2.1 Create `examples/sns/main.tf` — Lambda triggered by SNS topic with filter policy

## 3. Validation

- [x] 3.1 Run `terraform fmt -recursive` on new files
