# lambda-function EFS Support Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add optional Amazon EFS mount support to the `lambda-function` module so a container/zip Lambda can mount an EFS access point at a `/mnt/...` path.

**Architecture:** Add a single optional `efs_config` object variable. When set, the module emits a `file_system_config` block on `aws_lambda_function` and attaches a least-privilege EFS-client IAM policy scoped to the given access point. EFS requires VPC networking, so the module enforces (via precondition) that `subnet_ids`/`security_group_ids` are also provided. Mount-target ordering remains the caller's responsibility (documented), since the module only receives the access point ARN as a string.

**Tech Stack:** Terraform, AWS provider. Verification follows this repo's established pattern — `terraform fmt -recursive` + `terraform validate` on the module and a new `examples/efs/` example (no Terraform unit-test framework is used in this repo).

**Context for the implementer:**
- Driven by the `alamut` project (self-hosted Vaultwarden on Lambda), which stores a SQLite DB on EFS.
- AWS hard rule: a Lambda EFS `local_mount_path` **must** start with `/mnt`.
- AWS hard rule: a Lambda with `file_system_config` **must** also have `vpc_config`.
- The module's existing files: `variables.tf`, `main.tf`, `iam.tf`, `outputs.tf`, `versions.tf`, `README.md`. Relevant locals already present in `main.tf`: `has_vpc`, `is_zip`, `is_image`.
- The `README.md` mentions `existing_role_arn`/`attach_log_policy`, but those variables do **not** exist in the current `variables.tf`/`iam.tf`. Ignore that drift; plan against the actual code.

---

## File Structure

- Modify: `modules/lambda-function/variables.tf` — add `efs_config` variable.
- Modify: `modules/lambda-function/main.tf` — add `has_efs` local, `file_system_config` dynamic block, VPC precondition.
- Modify: `modules/lambda-function/iam.tf` — add EFS-client IAM policy (conditional on `efs_config`).
- Create: `examples/efs/main.tf` — example wiring EFS access point + VPC into the module (also the `validate` target).
- Modify: `modules/lambda-function/README.md` — document `efs_config` and usage caveats.

---

### Task 1: Add the `efs_config` variable

**Files:**
- Modify: `modules/lambda-function/variables.tf` (append a new variable in the "Optional: VPC" area, after `security_group_ids`)

- [ ] **Step 1: Add the variable**

Add to `modules/lambda-function/variables.tf` immediately after the `security_group_ids` variable (around line 110):

```hcl
# --- Optional: EFS ---

variable "efs_config" {
  description = "EFS mount configuration. When set, mounts an EFS access point into the function at local_mount_path (which must start with /mnt). Requires VPC config (subnet_ids + security_group_ids). The caller is responsible for ensuring EFS mount targets exist in the function's subnets before the function is created (use depends_on)."
  type = object({
    access_point_arn = string
    local_mount_path = string
  })
  default = null

  validation {
    condition     = var.efs_config == null || startswith(var.efs_config.local_mount_path, "/mnt")
    error_message = "efs_config.local_mount_path must start with /mnt (AWS Lambda requirement)."
  }
}
```

- [ ] **Step 2: Format**

Run: `terraform fmt modules/lambda-function/variables.tf`
Expected: file reformatted/clean, exit 0.

- [ ] **Step 3: Commit**

```bash
git add modules/lambda-function/variables.tf
git commit -m "feat(lambda-function): add efs_config variable"
```

---

### Task 2: Emit the `file_system_config` block and VPC precondition

**Files:**
- Modify: `modules/lambda-function/main.tf`

- [ ] **Step 1: Add the `has_efs` local**

In `modules/lambda-function/main.tf`, extend the `locals` block (after the `has_image_config` definition, before the closing `}` around line 14):

```hcl
  has_efs = var.efs_config != null
```

- [ ] **Step 2: Add the `file_system_config` dynamic block**

In the `aws_lambda_function "this"` resource, after the `vpc_config` dynamic block (after line 66) and before `depends_on`:

```hcl
  dynamic "file_system_config" {
    for_each = local.has_efs ? [1] : []

    content {
      arn              = var.efs_config.access_point_arn
      local_mount_path = var.efs_config.local_mount_path
    }
  }
```

- [ ] **Step 3: Add a precondition that EFS requires VPC**

In the existing `lifecycle` block of `aws_lambda_function "this"`, add a second `precondition` after the packaging precondition:

```hcl
    precondition {
      condition     = !local.has_efs || local.has_vpc
      error_message = "efs_config requires VPC configuration (both subnet_ids and security_group_ids must be set)."
    }
```

- [ ] **Step 4: Format and validate**

Run: `terraform fmt modules/lambda-function/main.tf && terraform -chdir=modules/lambda-function init -backend=false && terraform -chdir=modules/lambda-function validate`
Expected: `Success! The configuration is valid.`

- [ ] **Step 5: Commit**

```bash
git add modules/lambda-function/main.tf
git commit -m "feat(lambda-function): mount EFS access point via file_system_config"
```

---

### Task 3: Add the EFS-client IAM policy

**Files:**
- Modify: `modules/lambda-function/iam.tf`

- [ ] **Step 1: Add the EFS policy document, policy, and attachment**

Append to `modules/lambda-function/iam.tf` (after the "Additional policies" block, end of file):

```hcl
# --- EFS access policy (when an EFS file system is mounted) ---

data "aws_iam_policy_document" "efs" {
  count = local.has_efs ? 1 : 0

  statement {
    actions = [
      "elasticfilesystem:ClientMount",
      "elasticfilesystem:ClientWrite",
    ]

    # EFS client actions target the file system; scope to the specific
    # access point via condition (the module only receives the AP ARN).
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "elasticfilesystem:AccessPointArn"
      values   = [var.efs_config.access_point_arn]
    }
  }
}

resource "aws_iam_policy" "efs" {
  count = local.has_efs ? 1 : 0

  name   = "${var.function_name}-efs"
  policy = data.aws_iam_policy_document.efs[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "efs" {
  count = local.has_efs ? 1 : 0

  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.efs[0].arn
}
```

- [ ] **Step 2: Format and validate**

Run: `terraform fmt modules/lambda-function/iam.tf && terraform -chdir=modules/lambda-function validate`
Expected: `Success! The configuration is valid.`

- [ ] **Step 3: Commit**

```bash
git add modules/lambda-function/iam.tf
git commit -m "feat(lambda-function): grant least-privilege EFS client access"
```

---

### Task 4: Add the `examples/efs/` example

**Files:**
- Create: `examples/efs/main.tf`

- [ ] **Step 1: Write the example**

Create `examples/efs/main.tf`:

```hcl
# Generated by CLAUDE

provider "aws" {
  region = "eu-central-1"
}

# --- Minimal VPC scaffolding for the example ---

resource "aws_vpc" "this" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "this" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_security_group" "lambda" {
  name   = "efs-example-lambda"
  vpc_id = aws_vpc.this.id
}

# --- EFS file system + access point ---

resource "aws_efs_file_system" "this" {
  encrypted = true
}

resource "aws_efs_mount_target" "this" {
  file_system_id  = aws_efs_file_system.this.id
  subnet_id       = aws_subnet.this.id
  security_groups = [aws_security_group.lambda.id]
}

resource "aws_efs_access_point" "this" {
  file_system_id = aws_efs_file_system.this.id

  posix_user {
    uid = 1000
    gid = 1000
  }

  root_directory {
    path = "/data"
    creation_info {
      owner_uid   = 1000
      owner_gid   = 1000
      permissions = "0755"
    }
  }
}

# --- Lambda with EFS mounted ---

module "efs_consumer" {
  source = "../../modules/lambda-function"

  function_name = "efs-consumer"

  image = {
    uri = "123456789012.dkr.ecr.eu-central-1.amazonaws.com/efs-consumer:latest"
  }

  architecture = "arm64"

  subnet_ids         = [aws_subnet.this.id]
  security_group_ids = [aws_security_group.lambda.id]

  efs_config = {
    access_point_arn = aws_efs_access_point.this.arn
    local_mount_path = "/mnt/data"
  }

  # EFS mount targets must exist before the function is created.
  depends_on = [aws_efs_mount_target.this]

  tags = {
    Example = "efs"
  }
}

output "function_arn" {
  value = module.efs_consumer.function_arn
}
```

- [ ] **Step 2: Format and validate the example**

Run: `terraform fmt examples/efs/main.tf && terraform -chdir=examples/efs init -backend=false && terraform -chdir=examples/efs validate`
Expected: `Success! The configuration is valid.`

- [ ] **Step 3: Commit**

```bash
git add examples/efs/main.tf
git commit -m "docs(lambda-function): add EFS mount example"
```

---

### Task 5: Document `efs_config` in the module README

**Files:**
- Modify: `modules/lambda-function/README.md`

- [ ] **Step 1: Add an "Optional: EFS" inputs subsection**

In `modules/lambda-function/README.md`, after the "Optional: VPC" table (around line 90), add:

```markdown
### Optional: EFS

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `efs_config` | `object` | `null` | EFS mount configuration. When set, mounts an EFS access point into the function. Requires VPC config. See fields below. |

**`efs_config` object fields:**

| Field | Type | Description |
|-------|------|-------------|
| `access_point_arn` | `string` | ARN of the EFS access point to mount. The module attaches a least-privilege IAM policy (`elasticfilesystem:ClientMount`/`ClientWrite`) scoped to this access point. |
| `local_mount_path` | `string` | Path where the file system is mounted in the function. **Must start with `/mnt`** (AWS requirement). |

**Caveats:**
- Requires `subnet_ids` and `security_group_ids` (EFS access needs VPC networking). A precondition enforces this.
- The EFS **mount targets must exist in the function's subnets before the function is created**. The module cannot infer this ordering from an ARN string — add `depends_on = [aws_efs_mount_target.<name>]` in the calling configuration (see `examples/efs/`).
```

- [ ] **Step 2: Commit**

```bash
git add modules/lambda-function/README.md
git commit -m "docs(lambda-function): document efs_config input"
```

---

### Task 6: Full-repo validation

- [ ] **Step 1: Format the whole repo**

Run: `terraform fmt -recursive`
Expected: exit 0; lists any files reformatted (should be none if prior steps formatted correctly).

- [ ] **Step 2: Validate module and example**

Run:
```bash
terraform -chdir=modules/lambda-function init -backend=false && terraform -chdir=modules/lambda-function validate
terraform -chdir=examples/efs init -backend=false && terraform -chdir=examples/efs validate
```
Expected: `Success! The configuration is valid.` for both.

- [ ] **Step 3: Commit any formatting fixes**

```bash
git add -A
git commit -m "chore(lambda-function): fmt after EFS support" || echo "nothing to commit"
```

---

## Self-Review Checklist (performed)

- **Spec coverage:** `efs_config` variable (Task 1), `file_system_config` emission + VPC precondition (Task 2), EFS IAM (Task 3), example (Task 4), docs (Task 5), validation (Task 6) — covers the §7 prerequisite from the alamut design.
- **No placeholders:** all HCL shown in full.
- **Consistency:** local `has_efs`, variable `efs_config` (fields `access_point_arn`, `local_mount_path`), and IAM resources `aws_iam_policy.efs` / attachment are referenced consistently across tasks.
- **Pattern fit:** mirrors existing module conventions (dynamic blocks keyed off `locals`, `count`-gated IAM resources, example under `examples/`, fmt+validate verification).
