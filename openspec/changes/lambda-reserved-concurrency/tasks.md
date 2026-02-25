## 1. Add variable

- [x] 1.1 Add `reserved_concurrent_executions` variable to `modules/lambda-function/variables.tf` (type: number, default: null)

## 2. Wire to resource

- [x] 2.1 Add `reserved_concurrent_executions = var.reserved_concurrent_executions` to `aws_lambda_function` resource in `modules/lambda-function/main.tf`

## 3. Validation

- [x] 3.1 Run `terraform fmt` on the module
- [x] 3.2 Run `terraform validate` on the module
