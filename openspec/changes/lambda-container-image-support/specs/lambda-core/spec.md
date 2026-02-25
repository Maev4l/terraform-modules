## ADDED Requirements

### Requirement: Packaging mode validation
The module SHALL validate that exactly one of `zip` or `image` is provided. Both null or both set MUST produce a validation error.

#### Scenario: Neither zip nor image provided
- **WHEN** both `zip` and `image` are null
- **THEN** the module fails with a validation error indicating one packaging mode must be provided

#### Scenario: Both zip and image provided
- **WHEN** both `zip` and `image` are non-null
- **THEN** the module fails with a validation error indicating only one packaging mode is allowed

### Requirement: Container image packaging
The module SHALL support creating a Lambda function from a pre-built ECR container image when the `image` variable is provided.

#### Scenario: Minimal container image function
- **WHEN** the user provides `function_name` and `image = { uri = "123456.dkr.ecr.us-east-1.amazonaws.com/my-app:latest" }`
- **THEN** the module creates a Lambda function with `package_type = "Image"` and `image_uri` set to the provided URI

#### Scenario: Container image with overrides
- **WHEN** the user provides `image` with optional `command`, `entry_point`, or `working_directory`
- **THEN** the module configures the Lambda function's `image_config` block with the provided overrides

#### Scenario: Container image without overrides
- **WHEN** the user provides `image` with only `uri` (no command, entry_point, or working_directory)
- **THEN** the module creates the Lambda function without an `image_config` block, using the image's built-in CMD, ENTRYPOINT, and WORKDIR

### Requirement: Layers ignored in container mode
The module SHALL ignore the `layers` variable when using container image packaging, since Lambda layers are not supported with container images.

#### Scenario: Layers with container image
- **WHEN** the user provides `image` and also sets `layers`
- **THEN** the module ignores `layers` and creates the function without layers

## MODIFIED Requirements

### Requirement: Lambda function creation
The module SHALL create an `aws_lambda_function` resource. In zip mode, the user provides packaging via the `zip` object (`filename`, `runtime`, `handler`). In image mode, the user provides packaging via the `image` object (`uri`, and optional `command`, `entry_point`, `working_directory`).

#### Scenario: Minimal zip function creation
- **WHEN** the user provides `function_name` and `zip = { filename = "dist/app.zip", runtime = "python3.12", handler = "main.handler" }`
- **THEN** the module creates a Lambda function with `package_type = "Zip"`, the provided runtime, handler, filename, and `source_code_hash` computed from the zip file

#### Scenario: Minimal container function creation
- **WHEN** the user provides `function_name` and `image = { uri = "123456.dkr.ecr.us-east-1.amazonaws.com/my-app:latest" }`
- **THEN** the module creates a Lambda function with `package_type = "Image"` and `image_uri` set to the provided URI

#### Scenario: Full configuration
- **WHEN** the user provides optional parameters (`memory_size`, `timeout`, `architecture`, `ephemeral_storage`, `layers`, `description`, `publish`)
- **THEN** the module applies those values to the Lambda function, overriding defaults (except `layers` which is ignored in image mode)
