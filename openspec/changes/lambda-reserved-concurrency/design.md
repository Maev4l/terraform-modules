## Context

The lambda-function module creates AWS Lambda functions with configurable memory, timeout, VPC, and logging options. It currently lacks concurrency control - all functions use unreserved (shared) concurrency from the account pool.

## Goals / Non-Goals

**Goals:**
- Allow users to set reserved concurrent executions on Lambda functions
- Maintain backward compatibility (existing configs unchanged)

**Non-Goals:**
- Provisioned concurrency (warm starts) - separate feature
- Account-level concurrency management
- Auto-scaling policies

## Decisions

### 1. Variable type: nullable number

Use `number` with `default = null` rather than `-1` sentinel value.

- `null` = unreserved (AWS default behavior)
- `0` = function throttled (cannot execute)
- `1+` = reserved concurrent executions

**Rationale**: Terraform idiom - null means "don't set this attribute". Cleaner than sentinel values.

### 2. No validation block

AWS allows 0 to account limit. Validating would require knowing the account limit, which varies. Let AWS validate at apply time.

### 3. No output for this value

The value is pass-through (input = resource attribute). Users already know what they set. Adding output provides no new information.

## Risks / Trade-offs

**Risk**: User sets to 0 accidentally → function cannot execute
**Mitigation**: Clear variable description noting that 0 = throttled

**Trade-off**: No upper bound validation → apply-time errors if exceeding account limit
**Accepted**: Better than arbitrary limits that may be too restrictive
