## 1. Add variable

- [x] 1.1 Add `disable_execute_api_endpoint` variable to `modules/lambda-trigger-apigw/variables.tf` (type: bool, default: true)

## 2. Wire to resource

- [x] 2.1 Add `disable_execute_api_endpoint = var.disable_execute_api_endpoint` to `aws_apigatewayv2_api` resource in `modules/lambda-trigger-apigw/main.tf`

## 3. Validation

- [x] 3.1 Run `terraform fmt` on the module
- [x] 3.2 Run `terraform validate` on the module
