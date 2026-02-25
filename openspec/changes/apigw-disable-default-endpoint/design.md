## Context

The lambda-trigger-apigw module creates an HTTP API Gateway with a default execute endpoint. When users configure a custom domain, the default endpoint remains active, allowing bypass of any domain-level controls.

## Goals / Non-Goals

**Goals:**
- Allow users to disable the default execute API endpoint
- Maintain backward compatibility (default endpoint enabled by default)

**Non-Goals:**
- Auto-disable when custom domain is configured (user should explicitly choose)
- Custom domain management (already exists in domain.tf)

## Decisions

### 1. Explicit opt-in, not automatic

Even when `custom_domain` is set, don't automatically disable the default endpoint. User may want both during migration or for testing.

**Rationale**: Principle of least surprise. Changing behavior based on another variable creates hidden coupling.

### 2. Default to true (endpoint disabled)

Security by default. Users who need the default endpoint can explicitly enable it. Breaking change for existing users but safer default.

## Risks / Trade-offs

**Risk**: User forgets to disable default endpoint when using custom domain
**Mitigation**: Document the relationship in README; consider adding output showing both URLs

**Trade-off**: Two variables to manage (custom_domain + disable_execute_api_endpoint)
**Accepted**: Explicit is better than implicit
