## Context

The lambda-trigger-apigw module creates HTTP APIs. Browsers enforce CORS policy, blocking requests from different origins unless the server explicitly allows them. AWS API Gateway HTTP APIs support CORS via the `cors_configuration` block.

## Goals / Non-Goals

**Goals:**
- Allow users to configure CORS at the API level
- Support all CORS options: origins, methods, headers, credentials, max_age

**Non-Goals:**
- Per-route CORS configuration (API Gateway doesn't support this for HTTP APIs)
- Automatic CORS based on custom domain

## Decisions

### 1. Variable type: flexible (bool or object)

Support both simple and advanced usage like Serverless Framework:

```hcl
variable "cors" {
  description = "CORS configuration. Set to true for permissive defaults, or an object for custom config."
  type        = any
  default     = null

  validation {
    condition = var.cors == null || var.cors == false || var.cors == true || (
      try(var.cors.allow_origins, null) != null
    )
    error_message = "cors must be null, false, true, or an object with allow_origins."
  }
}
```

**Usage:**
- `cors = null` or `cors = false` → disabled
- `cors = true` → permissive defaults (like Serverless Framework)
- `cors = { allow_origins = [...] }` → custom config

### 2. Permissive defaults when `cors = true`

Match Serverless Framework behavior:

```hcl
locals {
  cors_defaults = {
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"]
    allow_headers     = ["Content-Type", "Authorization", "X-Amz-Date", "X-Api-Key", "X-Amz-Security-Token"]
    expose_headers    = []
    max_age           = 0
    allow_credentials = false
  }
}
```

**Rationale**: Simple `cors = true` covers 90% of use cases. Custom object for advanced needs.

## Risks / Trade-offs

**Risk**: User sets `allow_origins = ["*"]` with `allow_credentials = true` (browsers reject this)
**Mitigation**: Document this limitation. AWS validates at apply time.
