## ADDED Requirements

### Requirement: DynamoDB stream event source mapping
The module SHALL create an event source mapping that triggers the Lambda function from a DynamoDB stream.

#### Scenario: Event source mapping created
- **WHEN** the user provides `function_name`, `function_arn`, `role_name`, and `stream_arn`
- **THEN** the module creates an `aws_lambda_event_source_mapping` with the provided stream ARN as the event source and the Lambda function as the target

### Requirement: Starting position
The module SHALL support configuring the starting position for the stream with a sensible default.

#### Scenario: Default starting position
- **WHEN** the user does not provide `starting_position`
- **THEN** the module uses `LATEST` as the starting position

#### Scenario: Custom starting position
- **WHEN** the user provides `starting_position` (e.g., `TRIM_HORIZON`)
- **THEN** the module uses that value

### Requirement: Batch configuration
The module SHALL support configuring batch size and batching window with sensible defaults.

#### Scenario: Default batch settings
- **WHEN** the user does not provide `batch_size` or `maximum_batching_window_in_seconds`
- **THEN** the module uses: `batch_size = 100`, `maximum_batching_window_in_seconds = 0`

#### Scenario: Custom batch settings
- **WHEN** the user provides `batch_size` and/or `maximum_batching_window_in_seconds`
- **THEN** the module applies those values to the event source mapping

### Requirement: Event filtering
The module SHALL optionally support event filtering criteria to process only matching DynamoDB stream records.

#### Scenario: Filter criteria provided
- **WHEN** the user provides `filter_criteria`
- **THEN** the module configures the event source mapping's filter criteria block accordingly

#### Scenario: No filter criteria
- **WHEN** the user does not provide `filter_criteria`
- **THEN** the module creates the event source mapping without filtering (all records are processed)

### Requirement: Parallelization factor
The module SHALL support configuring the parallelization factor for concurrent processing of a single shard.

#### Scenario: Default parallelization
- **WHEN** the user does not provide `parallelization_factor`
- **THEN** the module uses the default value of `1`

#### Scenario: Custom parallelization
- **WHEN** the user provides `parallelization_factor`
- **THEN** the module applies that value to the event source mapping

### Requirement: IAM policy for DynamoDB stream access
The module SHALL create and attach an IAM policy to the Lambda execution role granting permissions to read from the DynamoDB stream.

#### Scenario: Stream read policy attached
- **WHEN** the module creates the event source mapping
- **THEN** it creates an IAM policy granting `dynamodb:GetRecords`, `dynamodb:GetShardIterator`, `dynamodb:DescribeStream`, and `dynamodb:ListStreams` on the provided `stream_arn`, and attaches it to the role identified by `role_name`

### Requirement: Tags
The module SHALL accept a `tags` map and apply it to all taggable resources created by the module.

#### Scenario: Tags propagation
- **WHEN** the user provides a `tags` map
- **THEN** the module applies those tags to all resources that support tagging
