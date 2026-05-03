# lambda-trigger-apigw — Design

This module provisions an AWS API Gateway HTTP API (v2) and wires one or more Lambda functions to it via the `integrations` map. Each integration owns a distinct subset of routes, allowing multiple Lambdas to share a single HTTP API while remaining independently deployable. Terraform practitioners should use this module whenever they need a serverless HTTP endpoint in front of one or more Lambda functions, with optional JWT authorization, CORS, custom domain (Route 53 + BYO ACM certificate), and control over the default execute-api endpoint.

## Architecture

Resources created by the module:

- `aws_apigatewayv2_api` — the HTTP API itself
- `aws_apigatewayv2_stage` — a single stage (defaults to `$default`, auto-deploy enabled)
- `aws_apigatewayv2_integration` — one per entry in the `integrations` map (i.e. one per Lambda)
- `aws_apigatewayv2_route` — one per `(integration, route)` pair across all integrations
- `aws_lambda_permission` — one per integration, grants API Gateway the right to invoke the function
- `aws_apigatewayv2_authorizer` — optional; created when `authorizer` is non-null
- `aws_apigatewayv2_domain_name` + `aws_apigatewayv2_api_mapping` + `aws_route53_record` — optional; created when `custom_domain` is non-null

There is exactly one HTTP API and one stage per module instance. Multiple Lambda functions are supported via the `integrations` map: each key in the map maps to one `aws_apigatewayv2_integration` and one `aws_lambda_permission`, and the routes listed under that key become `aws_apigatewayv2_route` resources targeting that integration. Routes across all integrations are flattened by the `route_pairs` local into a single `for_each` map keyed by `"integration_key:route"`, ensuring each `(method, path)` pair is a distinct Terraform resource.

When a custom domain is configured, it is always-or-nothing: all three domain resources (`aws_apigatewayv2_domain_name`, `aws_apigatewayv2_api_mapping`, `aws_route53_record`) are created together, driven by a single `local.create_domain` boolean.

## Components

### aws_apigatewayv2_api

The HTTP API resource. Created unconditionally; every other resource depends on it.

Key inputs:
- `api_name` (string, required) — the API is named `${api_name}-http-api`
- `cors` (any, default `null`) — controls the optional `cors_configuration` block; accepts `null`/`false`/`true`/object. This flexible type was chosen to match the Serverless Framework UX: `cors = true` applies permissive defaults, `cors = { allow_origins = [...] }` applies a custom config, and `null`/`false` disables CORS entirely. A `validation` block enforces the accepted shapes.
- `disable_execute_api_endpoint` (bool, default `true`) — passes through to the `disable_execute_api_endpoint` attribute on the API resource. Defaults to `true` (endpoint disabled) for security; users must set it to `false` when the API is fronted by CloudFront via the execute-api URL.
- `tags` (map(string), default `{}`) — applied to the API resource and all other taggable resources.

Design decision — `disable_execute_api_endpoint` is explicit, not automatic: even when `custom_domain` is set, the module does not automatically disable the default endpoint. This avoids hidden coupling between two independent variables and preserves the ability to use both endpoints during migration or testing.

### aws_apigatewayv2_stage

A single stage per API. Auto-deploy is always enabled so that route and integration changes take effect without a manual deployment action.

Key inputs:
- `stage_name` (string, default `"$default"`) — stage name; `$default` is the API Gateway v2 default stage that receives traffic without a path prefix.

### aws_apigatewayv2_integration and aws_lambda_permission

One integration and one permission resource per entry in `integrations`.

Key input — `integrations` (map(object), required):
```hcl
map(object({
  function_name = string
  function_arn  = string
  invoke_arn    = string
  routes        = list(string)
}))
```
At least one integration is required (enforced by a `validation` block). Integration type is always `AWS_PROXY` with `payload_format_version = "2.0"`. Each `aws_lambda_permission` uses `statement_id = "AllowAPIGatewayInvoke-${each.key}"` to ensure uniqueness when multiple integrations target different functions. The permission grants `apigateway.amazonaws.com` the `lambda:InvokeFunction` action with source ARN `${execution_arn}/*/*`, scoped to any stage and method on this API.

Design decision — resource-based policy via `aws_lambda_permission` (not `role_name`): API Gateway invokes Lambda through a resource-based policy rather than an IAM role. The module creates this permission itself, following the design principle that each trigger module manages its own IAM.

### aws_apigatewayv2_route

One route per `(integration, route)` pair. Routes are derived from `local.route_pairs`, a flattened map keyed by `"integration_key:route_key"` that allows a single `for_each` to span multiple integrations. Route keys use HTTP API syntax: `"METHOD /path"` (e.g. `"GET /api/resumes/{id}"`).

When an authorizer is configured (`local.create_authorizer = true`), every route sets `authorization_type = "JWT"` and `authorizer_id` to the created authorizer. When no authorizer is configured, routes default to `authorization_type = "NONE"`. All routes share the same authorizer — per-route authorization scopes are not supported in this version.

### aws_apigatewayv2_authorizer (optional)

Created in `authorizer.tf` when `var.authorizer != null`.

Key input — `authorizer` (object, default `null`):
```hcl
object({
  name             = string
  issuer           = string
  audience         = list(string)
  identity_sources = optional(list(string), ["$request.header.Authorization"])
})
```
`authorizer_type` is always `"JWT"`, supporting any OIDC-compliant provider (Cognito, Auth0, Okta). `identity_sources` defaults to `["$request.header.Authorization"]`, which is the standard location for Bearer tokens. Uses `count = local.create_authorizer ? 1 : 0` to follow the same conditional-resource pattern as `domain.tf`.

Design decision — optional object (same pattern as `custom_domain`): the object pattern eliminates impossible partial-configuration states and matches the pattern already established in the module for `custom_domain`.

Key output: `authorizer_id` — returns the authorizer's ID when configured, `null` otherwise.

### aws_apigatewayv2_domain_name, aws_apigatewayv2_api_mapping, aws_route53_record (optional)

Created in `domain.tf` when `var.custom_domain != null` (`local.create_domain = true`).

Key input — `custom_domain` (object, default `null`):
```hcl
object({
  domain_name     = string
  hosted_zone_id  = string
  certificate_arn = string
})
```
`aws_apigatewayv2_domain_name` uses `REGIONAL` endpoint type with `TLS_1_2` security policy. `aws_route53_record` creates an A alias record pointing the custom domain to the API Gateway target domain name. `aws_apigatewayv2_api_mapping` links the API and stage to the domain.

Design decision — grouped as a single object variable: all-or-nothing semantics prevent impossible states such as setting `domain_name` but omitting `certificate_arn`. ACM certificate creation is out of scope (BYO).

Key output: `custom_domain_url` — returns `"https://${var.custom_domain.domain_name}"` when configured, `null` otherwise.

## Data flow

At runtime, a client sends an HTTPS request. If a custom domain is configured, the Route 53 A alias record resolves the domain to the API Gateway regional endpoint; otherwise the client uses the default `https://{api-id}.execute-api.{region}.amazonaws.com` endpoint (if not disabled). API Gateway matches the request method and path against the configured routes and selects the matching `aws_apigatewayv2_route`. If a JWT authorizer is attached, API Gateway validates the Bearer token against the configured OIDC issuer and audience before forwarding. The route targets its `aws_apigatewayv2_integration` (type `AWS_PROXY`, format version 2.0), which invokes the associated Lambda function. API Gateway is authorized to call the function via the resource-based `aws_lambda_permission`. The Lambda function processes the event and returns a response, which API Gateway proxies back to the client.

## Error handling

Variable validations enforced by Terraform:

- `integrations` must contain at least one entry (`length(var.integrations) > 0`); an empty map is rejected at plan time.
- `cors` must be `null`, `false`, `true`, or an object containing `allow_origins`; any other shape is rejected at plan time.

AWS-side guardrails:

- `allow_origins = ["*"]` combined with `allow_credentials = true` is rejected by API Gateway at apply time (browsers also refuse such responses); this combination must be avoided in the `cors` object.
- ACM certificates used for custom domains must be in the same AWS region as the API Gateway (`us-east-1` is NOT required for HTTP API v2, unlike CloudFront); mismatched region certificates are rejected at apply time.
- JWT authorizer token validation failures return `401 Unauthorized` from API Gateway before the Lambda is invoked.

Known failure modes:

- Setting `disable_execute_api_endpoint = true` without a working custom domain will make the API unreachable. The module does not guard against this; operators must ensure a valid custom domain is configured.
- Pushing a new Lambda image to a tag (e.g. `:latest`) without updating `invoke_arn` does not produce a Terraform diff — the function will not update unless the ARN (or a digest-pinned `image_uri`) changes.

## Testing

Verification steps for this module:

- `terraform fmt -check` against `modules/lambda-trigger-apigw/`
- `terraform validate` against `modules/lambda-trigger-apigw/`
- Usage examples are present under `modules/lambda-trigger-apigw/examples/`:
  - `api-gateway/` — Lambda with HTTP API and custom domain
  - `api-gateway-cognito/` — Lambda with HTTP API and Cognito JWT authorizer
  - `container-image/` — Lambda backed by a container image
  - `multi-trigger/` — Lambda with multiple trigger types
  - `simple/` — minimal Lambda with no triggers
