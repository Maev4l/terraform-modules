## Why

Setting up an AWS Lambda function correctly requires wiring together many resources: the function itself, IAM roles and policies, CloudWatch log groups, triggers (API Gateway, S3, DynamoDB streams, Cognito), networking, and optionally custom domains. This is repetitive, error-prone, and the relationships between resources are easy to get wrong. A composable set of Terraform modules provides a one-stop shop that handles all of this with sane defaults while remaining fully configurable.

## What Changes

- **New core module (`lambda-function`)**: Creates the Lambda function, IAM execution role (with escape hatch for BYO role), CloudWatch log group, and base logging policy. Supports VPC configuration, environment variables, tags, and all standard Lambda settings with sensible defaults.
- **New trigger module (`lambda-trigger-apigw`)**: Creates an HTTP API Gateway (v2) with one or more routes pointing to a single Lambda. Optionally configures a custom domain with Route53 and ACM (BYO certificate). One API Gateway per Lambda — no shared gateway pattern.
- **New trigger module (`lambda-trigger-dynamodb`)**: Creates a DynamoDB stream event source mapping with filtering and batch configuration. Manages IAM policy for stream read access on the Lambda's execution role.
- **New trigger module (`lambda-trigger-s3`)**: Creates S3 bucket notifications and Lambda permission. Supports event type, prefix, and suffix filtering.
- **New trigger module (`lambda-trigger-cognito`)**: Wires a Lambda as a Cognito User Pool trigger (pre-sign-up, post-confirmation, pre-token-generation, etc.) with Lambda permission.
- **Usage examples** for each module and common combinations.

## Capabilities

### New Capabilities

- `lambda-core`: Core Lambda function creation with IAM role management (create or BYO), CloudWatch log group, VPC support, environment variables, tags, and all standard Lambda configuration.
- `trigger-apigw`: HTTP API Gateway (v2) trigger with multi-route support, optional custom domain (Route53 + BYO ACM certificate), and Lambda invocation permission.
- `trigger-dynamodb`: DynamoDB stream event source mapping trigger with filtering, batch configuration, and automatic IAM policy attachment.
- `trigger-s3`: S3 event notification trigger with event type, prefix, and suffix filtering, and Lambda invocation permission.
- `trigger-cognito`: Cognito User Pool trigger wiring with support for multiple trigger types and Lambda invocation permission.

### Modified Capabilities

None — greenfield project.

## Impact

- **New Terraform modules**: 5 new modules under `modules/` directory
- **Dependencies**: AWS provider (`hashicorp/aws`) required
- **IAM**: Core module creates IAM roles/policies by default; trigger modules for event source mappings (DynamoDB) attach policies to the execution role
- **AWS services touched**: Lambda, IAM, CloudWatch Logs, API Gateway v2, Route53, DynamoDB Streams, S3, Cognito
