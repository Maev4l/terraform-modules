## Why

The lambda-function module currently only supports zip file packaging. Lambda also supports container images (up to 10GB) stored in ECR, which is increasingly common for functions with large dependencies, custom runtimes, or teams that prefer container-based workflows. Supporting both packaging modes makes the module a true one-stop shop.

## What Changes

- **BREAKING: Restructure packaging variables** in the `lambda-function` module. Replace top-level `filename`, `runtime`, and `handler` with two mutually exclusive object variables: `zip` and `image`. Exactly one must be provided.
- **Add container image support**: When the `image` variable is provided, the module creates a Lambda function using a pre-built ECR image URI. Optional overrides for `command`, `entry_point`, and `working_directory` are supported via the `image` object.
- **Update all examples** to use the new `zip` block syntax.

## Capabilities

### New Capabilities

None — this extends the existing `lambda-core` capability.

### Modified Capabilities

- `lambda-core`: Packaging interface changes from flat variables (`filename`, `runtime`, `handler`) to grouped objects (`zip`, `image`). Adds container image support as a new packaging mode.

## Impact

- **Breaking change**: All consumers of `lambda-function` module must update from flat `filename`/`runtime`/`handler` variables to the `zip = { ... }` block
- **Modified files**: `modules/lambda-function/variables.tf`, `modules/lambda-function/main.tf`, all example `main.tf` files
- **No new dependencies**: Uses existing `aws_lambda_function` resource attributes (`image_uri`, `image_config`)
