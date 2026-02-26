## 1. Add variable and locals

- [x] 1.1 Add `cors` variable to `modules/lambda-trigger-apigw/variables.tf` (type: any, supports bool or object)
- [x] 1.2 Add locals for CORS defaults and resolved config in `modules/lambda-trigger-apigw/authorizer.tf`

## 2. Wire to resource

- [x] 2.1 Add dynamic `cors_configuration` block to `aws_apigatewayv2_api` resource in `modules/lambda-trigger-apigw/main.tf`

## 3. Validation

- [x] 3.1 Run `terraform fmt` on the module
- [x] 3.2 Run `terraform validate` on the module
