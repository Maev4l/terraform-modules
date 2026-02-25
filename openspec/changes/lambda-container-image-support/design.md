## Context

The `lambda-function` module currently has three required top-level variables (`filename`, `runtime`, `handler`) that assume zip packaging. To support container images, we need to restructure the packaging interface while keeping the rest of the module (IAM, logging, VPC, tags) unchanged.

The `aws_lambda_function` resource supports two mutually exclusive modes:
- **Zip**: `filename` + `runtime` + `handler` + `source_code_hash`
- **Container**: `image_uri` + optional `image_config` block (command, entry_point, working_directory). No `runtime` or `handler` on the resource itself — those are baked into the image.

## Goals / Non-Goals

**Goals:**

- Support container images from ECR as a packaging mode alongside zip
- Group packaging-related variables into `zip` and `image` object blocks
- Maintain all existing non-packaging functionality (IAM, logging, VPC, tags, outputs)
- Validate that exactly one of `zip` or `image` is provided

**Non-Goals:**

- Building or pushing Docker images — the image must already exist in ECR
- ECR repository creation or management
- Supporting `package_type = "Zip"` with S3 source — only local files
- Lambda layers with container images (not supported by AWS)

## Decisions

### Packaging variables as mutually exclusive objects

Replace `filename`, `runtime`, `handler` with two object variables:

```hcl
variable "zip" {
  type = object({
    filename = string
    runtime  = string
    handler  = string
  })
  default = null
}

variable "image" {
  type = object({
    uri               = string
    command           = optional(list(string))
    entry_point       = optional(list(string))
    working_directory = optional(string)
  })
  default = null
}
```

**Rationale:** Groups related variables by mode. The `null` default on both allows Terraform validation to enforce exactly-one-provided. Follows the same pattern as `custom_domain` in the API Gateway trigger module.

**Alternatives considered:**
- Single `packaging` object with a `type` discriminator — rejected because the fields differ completely between modes, making the type overly complex
- Keep flat variables + add `image_uri` — rejected because it creates ambiguity about which fields apply in which mode

### Conditional resource configuration

The `aws_lambda_function` resource uses `package_type` to switch modes:

```hcl
package_type     = var.zip != null ? "Zip" : "Image"
filename         = var.zip != null ? var.zip.filename : null
runtime          = var.zip != null ? var.zip.runtime : null
handler          = var.zip != null ? var.zip.handler : null
source_code_hash = var.zip != null ? filebase64sha256(var.zip.filename) : null
image_uri        = var.image != null ? var.image.uri : null
```

With a dynamic `image_config` block when overrides are provided.

**Rationale:** Simple ternary expressions. No separate resources or modules needed — `aws_lambda_function` handles both modes natively.

### Layers exclusion for container mode

Lambda layers are not supported with container images (AWS limitation). The `layers` variable remains but only applies in zip mode. The module should ignore `layers` in container mode rather than erroring — the user might share a common variable set across functions.

### No source_code_hash equivalent for container images

For zip files, `source_code_hash = filebase64sha256(...)` triggers updates when the zip changes. For container images, Terraform detects changes when `image_uri` changes (e.g., different tag or digest). Users should use image digests (`@sha256:...`) or unique tags for reliable update detection.

**Rationale:** There's no local file to hash for container images. The ECR image URI is the change signal.

## Risks / Trade-offs

**[Validation limited to plan time]** → Terraform's `validation` blocks can check that exactly one of `zip`/`image` is non-null, but complex cross-field validation (e.g., layers + image) can only be warned about in documentation. This is acceptable — Terraform modules commonly rely on documentation for usage constraints.

**[No automatic image change detection with mutable tags]** → If a user uses `image_uri = "repo:latest"`, Terraform won't detect when the image behind that tag changes. Mitigated by documentation recommending digest-based URIs or unique tags.
