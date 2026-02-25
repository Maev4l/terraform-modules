<!-- Edited by CLAUDE -->

# Terraform AWS Modules

A collection of composable Terraform modules for deploying AWS infrastructure with sane defaults and minimal configuration.

## Modules

### Lambda

Core module for creating Lambda functions with IAM, CloudWatch logging, and optional VPC support. Supports both zip and container image packaging.

| Module | Description | IAM Model |
|--------|-------------|-----------|
| [lambda-function](modules/lambda-function/) | Core Lambda function with IAM role, CloudWatch log group, VPC support | Creates role (or BYO) |
| [lambda-trigger-apigw](modules/lambda-trigger-apigw/) | HTTP API (API Gateway v2) with routes, custom domain, JWT authorizer | Push (resource-based) |
| [lambda-trigger-dynamodb](modules/lambda-trigger-dynamodb/) | DynamoDB Streams event source mapping with filtering | Pull (role-based) |
| [lambda-trigger-s3](modules/lambda-trigger-s3/) | S3 bucket notifications on object events | Push (resource-based) |
| [lambda-trigger-cognito](modules/lambda-trigger-cognito/) | Cognito User Pool trigger hooks | Push (resource-based) |
| [lambda-trigger-sns](modules/lambda-trigger-sns/) | SNS topic subscription with filter policy | Push (resource-based) |
| [lambda-trigger-sqs](modules/lambda-trigger-sqs/) | SQS queue polling with batching and partial failure reporting | Pull (role-based) |

### Static Hosting

| Module | Description |
|--------|-------------|
| [s3-static-site](modules/s3-static-site/) | S3 + CloudFront static website hosting with custom domain, SPA support |

## Examples

| Example | Description |
|---------|-------------|
| [simple](examples/simple/) | Minimal Lambda function |
| [api-gateway](examples/api-gateway/) | Lambda behind HTTP API with routes |
| [api-gateway-cognito](examples/api-gateway-cognito/) | HTTP API with JWT authorizer (Cognito) |
| [multi-trigger](examples/multi-trigger/) | Lambda with multiple triggers |
| [container-image](examples/container-image/) | Lambda from ECR container image |
| [remote-source](examples/remote-source/) | Referencing modules from GitHub |
| [sns](examples/sns/) | Lambda triggered by SNS topic |
| [sqs](examples/sqs/) | Lambda triggered by SQS queue |
| [static-site](examples/static-site/) | S3 static site with CloudFront and custom domain |

## Requirements

- Terraform >= 1.5
- AWS Provider >= 5.0
