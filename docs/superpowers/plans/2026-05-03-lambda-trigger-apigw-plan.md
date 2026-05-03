# lambda-trigger-apigw — Implementation plan (frozen migration record)

> **Note:** Superpowers plans are normally written for upcoming work. This plan is a frozen record of work already completed, migrated from OpenSpec `tasks.md` files in the now-deleted `openspec/` tree. It is preserved for traceability and is **not intended to be executed** — the corresponding terraform module is already implemented and shipping.

## Tasks

### From change: lambda-modules

(trigger-apigw-relevant tasks only — tasks 3.x)

## 3. Trigger module: lambda-trigger-apigw

- [x] 3.1 Create `modules/lambda-trigger-apigw/variables.tf` with: `function_name`, `function_arn`, `invoke_arn`, `routes`, `stage_name`, `custom_domain`, `tags`
- [x] 3.2 Create `modules/lambda-trigger-apigw/main.tf` with `aws_apigatewayv2_api`, `aws_apigatewayv2_stage`, `aws_apigatewayv2_integration`, `aws_apigatewayv2_route` (for_each on routes), `aws_lambda_permission`
- [x] 3.3 Create `modules/lambda-trigger-apigw/domain.tf` with conditional `aws_apigatewayv2_domain_name`, `aws_apigatewayv2_api_mapping`, `aws_route53_record` (A alias) — created only when `custom_domain` is not null
- [x] 3.4 Create `modules/lambda-trigger-apigw/outputs.tf` exposing `api_id`, `api_endpoint`, `execution_arn`, `stage_id`, `custom_domain_url`
- [x] 3.5 Create `modules/lambda-trigger-apigw/versions.tf` with required provider

### From change: apigw-authorizer

## 1. Add authorizer variable

- [x] 1.1 Add `authorizer` object variable to `modules/lambda-trigger-apigw/variables.tf` with `name`, `issuer`, `audience`, and optional `identity_sources` (default `["$request.header.Authorization"]`), null by default

## 2. Create authorizer resource

- [x] 2.1 Create `modules/lambda-trigger-apigw/authorizer.tf` with `local.create_authorizer` boolean and `aws_apigatewayv2_authorizer` resource (type JWT, conditional on count)

## 3. Wire authorizer to routes

- [x] 3.1 Update `aws_apigatewayv2_route` in `main.tf` to conditionally set `authorization_type` and `authorizer_id` based on `local.create_authorizer`

## 4. Add output

- [x] 4.1 Add `authorizer_id` output to `modules/lambda-trigger-apigw/outputs.tf` (null when no authorizer)

## 5. Cognito example

- [x] 5.1 Create `examples/api-gateway-cognito/main.tf` with Cognito User Pool, User Pool Client, Lambda function module, and API Gateway trigger module using the `authorizer` object

## 6. Validation

- [x] 6.1 Run `terraform fmt -recursive` on modified and new files

### From change: apigw-cors

## 1. Add variable and locals

- [x] 1.1 Add `cors` variable to `modules/lambda-trigger-apigw/variables.tf` (type: any, supports bool or object)
- [x] 1.2 Add locals for CORS defaults and resolved config in `modules/lambda-trigger-apigw/authorizer.tf`

## 2. Wire to resource

- [x] 2.1 Add dynamic `cors_configuration` block to `aws_apigatewayv2_api` resource in `modules/lambda-trigger-apigw/main.tf`

## 3. Validation

- [x] 3.1 Run `terraform fmt` on the module
- [x] 3.2 Run `terraform validate` on the module

### From change: apigw-disable-default-endpoint

## 1. Add variable

- [x] 1.1 Add `disable_execute_api_endpoint` variable to `modules/lambda-trigger-apigw/variables.tf` (type: bool, default: true)

## 2. Wire to resource

- [x] 2.1 Add `disable_execute_api_endpoint = var.disable_execute_api_endpoint` to `aws_apigatewayv2_api` resource in `modules/lambda-trigger-apigw/main.tf`

## 3. Validation

- [x] 3.1 Run `terraform fmt` on the module
- [x] 3.2 Run `terraform validate` on the module

## Verification performed

- `terraform fmt` (formatting check)
- `terraform validate` (provider schema validation)
- Manual usage in `examples/` (api-gateway, api-gateway-cognito, multi-trigger, simple, container-image)
