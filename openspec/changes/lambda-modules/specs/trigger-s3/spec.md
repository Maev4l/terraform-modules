## ADDED Requirements

### Requirement: S3 event notification
The module SHALL create an S3 bucket notification that triggers the Lambda function on specified events.

#### Scenario: Notification created
- **WHEN** the user provides `function_name`, `function_arn`, `bucket_id`, `bucket_arn`, and `events`
- **THEN** the module creates an `aws_s3_bucket_notification` on the specified bucket with a Lambda function target for the specified events

### Requirement: Event types
The module SHALL require the user to specify which S3 event types trigger the Lambda function.

#### Scenario: Object created events
- **WHEN** the user provides `events = ["s3:ObjectCreated:*"]`
- **THEN** the module configures the notification to trigger on all object creation events

#### Scenario: Multiple event types
- **WHEN** the user provides `events = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"]`
- **THEN** the module configures the notification to trigger on both object creation and removal events

### Requirement: Prefix and suffix filtering
The module SHALL optionally filter S3 events by object key prefix and/or suffix.

#### Scenario: Prefix filter
- **WHEN** the user provides `filter_prefix = "images/"`
- **THEN** the module configures the notification to only trigger for objects with keys starting with `images/`

#### Scenario: Suffix filter
- **WHEN** the user provides `filter_suffix = ".jpg"`
- **THEN** the module configures the notification to only trigger for objects with keys ending with `.jpg`

#### Scenario: Both prefix and suffix
- **WHEN** the user provides both `filter_prefix` and `filter_suffix`
- **THEN** the module applies both filters to the notification

#### Scenario: No filters
- **WHEN** the user does not provide `filter_prefix` or `filter_suffix`
- **THEN** the module creates the notification without key filtering (all matching events trigger the Lambda)

### Requirement: Lambda invocation permission
The module SHALL create a resource-based policy allowing the S3 bucket to invoke the Lambda function.

#### Scenario: Permission created
- **WHEN** the module creates the bucket notification
- **THEN** it creates an `aws_lambda_permission` allowing the S3 service (`s3.amazonaws.com`) to invoke the Lambda function, scoped to the provided `bucket_arn`

### Requirement: Tags
The module SHALL accept a `tags` map. Since S3 bucket notifications and Lambda permissions do not support tags, tags are accepted for interface consistency but may not be applied to resources.

#### Scenario: Tags accepted
- **WHEN** the user provides a `tags` map
- **THEN** the module accepts the variable without error
