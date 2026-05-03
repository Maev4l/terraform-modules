# lambda-trigger-cognito — Design

This module grants a Cognito User Pool permission to invoke a Lambda function by creating a resource-based Lambda permission. Terraform practitioners use it when they need to wire a Lambda as a Cognito User Pool trigger (pre-sign-up, post-confirmation, pre-token-generation, etc.) and want a consistent interface with other Lambda trigger modules. The primary AWS services involved are AWS Lambda and Amazon Cognito.

> **Important:** This module only manages the `aws_lambda_permission` resource. Due to an AWS provider limitation, Cognito Lambda trigger types (the `lambda_config` block) can only be set inside the `aws_cognito_user_pool` resource itself — there is no standalone resource for attaching triggers to an existing user pool. The `lambda_config` wiring must be done in the caller's `aws_cognito_user_pool` resource.

## Architecture

Resources created by this module:

- `aws_lambda_permission` — resource-based policy allowing the Cognito User Pool to invoke the Lambda function

The module uses two data sources at plan time (`aws_region.current`, `aws_caller_identity.current`) to construct the fully-qualified `source_arn` for the permission, scoping invocation rights to the specific user pool rather than all Cognito pools in the account.

No IAM roles or policies are created. The permission is resource-based (attached to the Lambda function), following the same pattern as the S3 and API Gateway trigger modules. One `aws_lambda_permission` is created per module invocation.

## Components

### aws_lambda_permission

The Lambda permission allows the Cognito Identity Provider service (`cognito-idp.amazonaws.com`) to call `lambda:InvokeFunction` on the target function. The `source_arn` is scoped to the specific user pool, following the principle of least privilege and preventing confused-deputy attacks.

Key inputs:

| Variable | Type | Required | Purpose |
|---|---|---|---|
| `function_name` | `string` | yes | Name of the Lambda function; used to construct the `statement_id` for the permission (`AllowCognitoInvoke-<function_name>`). |
| `function_arn` | `string` | yes | ARN of the Lambda function; set as the `function_name` parameter of the permission resource. |
| `user_pool_id` | `string` | yes | ID of the Cognito User Pool; used to build the `source_arn` as `arn:aws:cognito-idp:<region>:<account>:userpool/<user_pool_id>`. |

Key outputs:

- `permission_id` — the ID of the `aws_lambda_permission` resource, useful for dependency ordering in Terraform.

Design decision — permission-only scope: The original spec described managing `lambda_config` (trigger type assignment) as well. The implementation intentionally deviates: Cognito triggers can only be configured via the `lambda_config` block within `aws_cognito_user_pool`, and there is no AWS provider resource for attaching triggers to an existing pool without replacing it. Attempting to manage `lambda_config` in a trigger module would conflict with any caller-owned `aws_cognito_user_pool` resource. The module therefore provides only the permission, keeping a consistent interface with other trigger modules while documenting the caller responsibility clearly.

Design decision — no `triggers` variable: The spec included a `triggers` list variable for specifying which trigger types to configure. This variable is absent from the implemented module because trigger type assignment belongs in `lambda_config` on the user pool resource, not in a standalone module.

Design decision — no `tags` variable: The spec required a `tags` map for interface consistency. The `aws_lambda_permission` resource does not support tags, so there is nothing to propagate; the variable was omitted from the implementation.

## Data flow

At runtime, a Cognito event (such as a user initiating sign-up) causes the Cognito User Pool to invoke the configured Lambda function for the matching trigger type. Cognito authenticates the invocation using the resource-based policy this module creates: the policy allows `cognito-idp.amazonaws.com` to call `lambda:InvokeFunction`, with the `source_arn` scoped to the specific user pool ARN.

The Lambda function executes and returns a response object to Cognito. Cognito interprets the response according to the trigger contract for each trigger type (for example, `pre_sign_up` may auto-confirm the user or return a validation error, while `pre_token_generation` may augment token claims). If the Lambda function raises an unhandled exception, Cognito surfaces an error to the end user and the operation fails.

## Error handling

Variable validations enforced by the module:

- No Terraform `validation { ... }` blocks are defined in `variables.tf`; all three required variables (`function_name`, `function_arn`, `user_pool_id`) must be provided or Terraform will error on the missing required attribute.

AWS-side guardrails:

- If the `user_pool_id` is invalid or belongs to a different account/region, AWS will reject the permission creation at apply time with an API error.
- If the Lambda function ARN does not exist, AWS will reject the permission resource at apply time.
- Trigger type validity is enforced by the `aws_cognito_user_pool` resource in the caller, not by this module.

Known failure modes:

- Caller forgets to add `lambda_config` to `aws_cognito_user_pool`: the permission exists but Cognito never invokes the Lambda, silently. No Terraform error is raised.
- Drift between the permission's `source_arn` (locked to `user_pool_id`) and the actual user pool used in `lambda_config`: the invocation will be denied by the resource-based policy.

## Testing

Verification for this module:

- `terraform fmt -check` on `modules/lambda-trigger-cognito/` to verify formatting compliance.
- `terraform validate` on `modules/lambda-trigger-cognito/` to verify provider schema compliance (requires AWS provider initialization).
- Usage example in `examples/multi-trigger/main.tf` demonstrates this module in combination with other Lambda trigger modules.
