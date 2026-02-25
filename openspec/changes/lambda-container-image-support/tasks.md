## 1. Restructure packaging variables

- [x] 1.1 Replace `filename`, `runtime`, `handler` variables with `zip` object variable (type: `object({ filename = string, runtime = string, handler = string })`, default: `null`) in `modules/lambda-function/variables.tf`
- [x] 1.2 Add `image` object variable (type: `object({ uri = string, command = optional(list(string)), entry_point = optional(list(string)), working_directory = optional(string) })`, default: `null`) in `modules/lambda-function/variables.tf`
- [x] 1.3 Add validation block ensuring exactly one of `zip` or `image` is non-null

## 2. Update core module main.tf

- [x] 2.1 Add locals for packaging mode: `is_zip = var.zip != null`, `is_image = var.image != null`, `has_image_config` for override detection
- [x] 2.2 Update `aws_lambda_function` resource: add `package_type`, make `filename`/`runtime`/`handler`/`source_code_hash` conditional on zip mode, add `image_uri` conditional on image mode
- [x] 2.3 Add dynamic `image_config` block for container image overrides (command, entry_point, working_directory)
- [x] 2.4 Make `layers` conditional on zip mode (set to `[]` in image mode)

## 3. Update examples

- [x] 3.1 Update `examples/simple/main.tf` to use `zip = { ... }` block
- [x] 3.2 Update `examples/api-gateway/main.tf` to use `zip = { ... }` block
- [x] 3.3 Update `examples/multi-trigger/main.tf` to use `zip = { ... }` block

## 4. Validation

- [x] 4.1 Run `terraform fmt -recursive` on all modified files
