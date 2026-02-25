## Context

This is a greenfield Terraform repository. There are no existing modules, state, or conventions to work around. The goal is a composable set of Terraform modules for AWS Lambda: a core module for the function itself, and separate trigger modules that wire event sources to the function.

The primary consumer is a Terraform practitioner who packages their own Lambda code (zip file built locally) and wants a clean, predictable interface to deploy it with the right IAM, logging, triggers, and optionally a custom domain.

## Goals / Non-Goals

**Goals:**

- One core module that handles everything a Lambda function needs (function, IAM, logging)
- Separate trigger modules that are independently composable — attach zero or many to one function
- Sane defaults for every setting, with full override capability
- Each module is self-contained: it creates all resources it needs, including IAM policies for triggers
- Consistent interface patterns across all modules

**Non-Goals:**

- Lambda code packaging or building — the practitioner provides a pre-built zip file
- REST API Gateway (v1) support — HTTP API (v2) only; REST may come as a separate module later
- Shared API Gateway pattern (multiple Lambdas behind one gateway) — each API Gateway maps to exactly one Lambda
- ACM certificate creation — BYO certificate for custom domains
- CloudWatch alarms or dashboards — observability beyond log groups is out of scope
- Lambda@Edge or CloudFront integration

## Decisions

### Module composition: separate modules per trigger (not a single monolith)

Each trigger type (API Gateway, S3, DynamoDB, Cognito) is its own module rather than options within a single module.

**Rationale:** Trigger types create fundamentally different Terraform resources with different variable signatures. A monolith would require large conditional blocks and variables that only apply to specific trigger types. Separate modules keep each interface focused and allow users to attach multiple trigger types to one function.

**Alternatives considered:**
- Single module with `trigger_type` variable — rejected due to interface bloat and complex conditionals
- Hybrid (common triggers inline, exotic ones separate) — rejected for inconsistency

### IAM ownership: trigger modules manage their own IAM

Trigger modules that need role-based IAM (DynamoDB streams) accept `role_name` and attach the necessary policies themselves. Triggers using resource-based policies (API Gateway, S3, Cognito) create `aws_lambda_permission` and don't need `role_name`.

**Rationale:** The trigger module knows exactly what IAM it needs. Pushing this to the user defeats the "one-stop shop" goal.

**Interface split:**
- All trigger modules require: `function_name`, `function_arn`
- Event source mapping triggers (DynamoDB) additionally require: `role_name`
- API Gateway additionally requires: `invoke_arn`

### BYO role: `existing_role_arn` replaces boolean `create_role`

Instead of two variables (`create_role` boolean + `existing_role_arn` string), a single `existing_role_arn` variable controls behavior. When `null` (default), the module creates the role. When set, it uses the provided role.

**Rationale:** Eliminates impossible state (`create_role = true` + `existing_role_arn` set). The presence of the ARN is the signal.

### CloudWatch log policy on BYO roles: `attach_log_policy` escape hatch

When using a BYO role, the module attaches the CloudWatch Logs policy to it by default (`attach_log_policy = true`). This can be disabled for teams whose centrally-managed roles already include log permissions.

**Rationale:** Most BYO roles won't have the specific log group policy. Attaching it by default makes things "just work" while the escape hatch respects teams with strict IAM boundaries.

### API Gateway: one gateway per Lambda, no shared gateway

Each `lambda-trigger-apigw` instance creates its own HTTP API with one or more routes, all pointing to the same Lambda function. There is no mechanism to share an API Gateway across multiple Lambda functions.

**Rationale:** Eliminates resource conflicts when multiple trigger module instances target the same API. The Lambda handles routing internally (e.g., via FastAPI, Express, or a custom router). This is the common pattern for Lambda-backed APIs.

### Custom domain: grouped as an object variable

Domain configuration (`domain_name`, `hosted_zone_id`, `certificate_arn`) is a single `custom_domain` object variable that defaults to `null`. When provided, the module creates the API Gateway custom domain, Route53 A record alias, and API mapping.

**Rationale:** All-or-nothing semantics — you can't accidentally set `domain_name` but forget `certificate_arn`. Cleaner interface than three separate optional variables with cross-validation.

### Tags: propagated to all resources

Both the core module and trigger modules accept a `tags` map variable, merged into every resource they create.

**Rationale:** Standard Terraform pattern. Enables cost allocation, ownership tracking, and compliance.

## Risks / Trade-offs

**[One gateway per Lambda limits API composition]** → This is a deliberate scope constraint. Teams needing multiple Lambdas behind one API Gateway should compose at a higher level or use a separate API Gateway module. A future `lambda-trigger-apigw-rest` module could address more complex routing.

**[Trigger modules attaching IAM to BYO roles may surprise users]** → Mitigated by `attach_log_policy` escape hatch on core module. DynamoDB trigger module always attaches its stream read policy — documented clearly. Users who need full IAM control can manage policies externally and use minimal trigger module features.

**[HTTP API v2 only — no REST API support]** → Acceptable for initial release. HTTP API covers the majority of use cases at lower cost and complexity. REST API can be added as a separate trigger module (`lambda-trigger-apigw-rest`) without breaking changes.

**[No certificate creation]** → Users must have an ACM certificate before using custom domains. This is standard practice (certificates are often shared across services) and avoids the complexity of DNS validation lifecycle in the module.
