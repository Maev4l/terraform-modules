# lambda-trigger-apigw

Creates an HTTP API Gateway v2 endpoint with a JWT authorizer and fans out multiple Lambda integrations, each owning a subset of routes.

## What it provisions

- 1 × `aws_apigatewayv2_api` (HTTP API)
- 1 × `aws_apigatewayv2_authorizer` (JWT)
- 1 × `aws_apigatewayv2_stage` (`$default`, auto-deploy)
- 1 × `aws_apigatewayv2_domain_name` + `aws_apigatewayv2_api_mapping`
- 1 × `aws_route53_record` (A / alias → API Gateway domain)
- N × `aws_apigatewayv2_integration` (one per entry in `integrations`)
- M × `aws_apigatewayv2_route` (one per `METHOD /path` across all integrations)
- N × `aws_lambda_permission` (one per integration, unique `statement_id`)

## Usage

```hcl
module "api" {
  source = "github.com/Maev4l/terraform-modules//modules/lambda-trigger-apigw?ref=v1.7.0"  # new tag cut after this rewrite

  api_name                     = "visual-resumes"
  disable_execute_api_endpoint = false   # required when fronted by CloudFront

  authorizer = {
    name     = "visual-resumes-cognito-authorizer"
    issuer   = "https://cognito-idp.${var.region}.amazonaws.com/${data.aws_cognito_user_pools.shared.ids[0]}"
    audience = [local.cognito_client_id]
  }

  cors = false  # CloudFront is same-origin; API is only hit via /api/* path

  integrations = {
    api = {
      function_name = module.lambda_api.function_name
      function_arn  = module.lambda_api.function_arn
      invoke_arn    = module.lambda_api.invoke_arn
      routes = [
        "GET /api/resumes",
        "POST /api/resumes",
        "GET /api/resumes/{id}",
        "PUT /api/resumes/{id}",
        "DELETE /api/resumes/{id}",
        "POST /api/resumes/{id}/photo",
        "POST /api/resumes/{id}/revoke",
      ]
    }
    renderer = {
      function_name = module.lambda_renderer.function_name
      function_arn  = module.lambda_renderer.function_arn
      invoke_arn    = module.lambda_renderer.invoke_arn
      routes = [
        "POST /api/resumes/{id}/publish",
      ]
    }
  }
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `api_name` | `string` | — | Name of the HTTP API (used as `${api_name}-http-api` and for tags). |
| `integrations` | `map(object(...))` | — | See below. |
| `stage_name` | `string` | `"$default"` | API Gateway stage name. |
| `custom_domain` | `object({domain_name, hosted_zone_id, certificate_arn})` or `null` | `null` | Set to skip custom domain creation. |
| `authorizer` | `object({name, issuer, audience, identity_sources?})` or `null` | `null` | JWT authorizer applied to all routes when set. |
| `cors` | `null` / `false` / `true` / `object` | `null` | `true` for permissive defaults, object for custom config. |
| `disable_execute_api_endpoint` | `bool` | `true` | Set to `false` when fronted by CloudFront via execute-api URL. |
| `tags` | `map(string)` | `{}` | Tags applied to created resources. |

### `integrations` shape

```hcl
map(object({
  function_name = string
  function_arn  = string
  invoke_arn    = string
  routes        = list(string)  # HTTP API route keys: "METHOD /path"
}))
```

## Outputs

| Name | Description |
|---|---|
| `api_id` | HTTP API ID. |
| `api_endpoint` | Default execute-api endpoint. |
| `custom_domain` | Custom domain name. |
| `integration_ids` | Map of integration key → integration ID. |

## Breaking change from previous version

This module previously accepted `function_name`, `function_arn`, `invoke_arn`, `routes` at the module level (single Lambda). It now requires the `integrations` map. There is no backward-compatibility shim — consumers must migrate.
