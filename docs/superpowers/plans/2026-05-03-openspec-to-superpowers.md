# OpenSpec → Superpowers Conversion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace OpenSpec with superpowers — synthesize 9 per-module design docs + 9 frozen-plan docs from existing OpenSpec sources, then delete the OpenSpec tree, the four `openspec-*` skills, and the `opsx` slash-command folder.

**Architecture:** One-shot synthesis. Each terraform module is an independent task: read its OpenSpec source files (where they exist) plus its `.tf` files, produce one design doc and one frozen plan in `docs/superpowers/specs/` and `docs/superpowers/plans/`. After all 18 files exist and spot-checks pass, perform full teardown of OpenSpec artifacts. Single commit at the end (commit gated on explicit user approval per the user's "never commit automatically" rule).

**Tech Stack:** Markdown documentation only. No code, no tests, no CI changes. The terraform modules under `modules/` are already implemented and are not modified by this plan — they are only **read** as a source of truth when synthesizing designs.

**Spec:** `docs/superpowers/specs/2026-05-03-openspec-to-superpowers-design.md`

---

## Conventions used by this plan

- **Source paths** are absolute or rooted at the repo root `/Users/jrsue/dev/repos/terraform-modules/`.
- **Output paths** for designs are `docs/superpowers/specs/2026-05-03-<module>-design.md`.
- **Output paths** for plans are `docs/superpowers/plans/2026-05-03-<module>-plan.md`.
- The "design template" and "frozen plan template" referenced by every per-module task are reproduced verbatim under **Templates** below — do not paraphrase, copy them.
- "Code is the source of truth": when OpenSpec content disagrees with the actual `.tf` files, the doc reflects the code.
- No automatic commits. The commit step at the end requires explicit user approval before running `git commit`.

## File Structure (target state)

```
docs/superpowers/
├── specs/
│   ├── 2026-05-03-openspec-to-superpowers-design.md   (already exists; written during brainstorming)
│   ├── 2026-05-03-lambda-function-design.md
│   ├── 2026-05-03-lambda-trigger-apigw-design.md
│   ├── 2026-05-03-lambda-trigger-cognito-design.md
│   ├── 2026-05-03-lambda-trigger-dynamodb-design.md
│   ├── 2026-05-03-lambda-trigger-s3-design.md
│   ├── 2026-05-03-lambda-trigger-scheduler-design.md
│   ├── 2026-05-03-lambda-trigger-sns-design.md
│   ├── 2026-05-03-lambda-trigger-sqs-design.md
│   └── 2026-05-03-s3-static-site-design.md
└── plans/
    ├── 2026-05-03-openspec-to-superpowers.md           (this file)
    ├── 2026-05-03-lambda-function-plan.md
    ├── 2026-05-03-lambda-trigger-apigw-plan.md
    ├── 2026-05-03-lambda-trigger-cognito-plan.md
    ├── 2026-05-03-lambda-trigger-dynamodb-plan.md
    ├── 2026-05-03-lambda-trigger-s3-plan.md
    ├── 2026-05-03-lambda-trigger-scheduler-plan.md
    ├── 2026-05-03-lambda-trigger-sns-plan.md
    ├── 2026-05-03-lambda-trigger-sqs-plan.md
    └── 2026-05-03-s3-static-site-plan.md
```

Removed at end of plan: `openspec/`, `.claude/skills/openspec-{propose,explore,apply-change,archive-change}/`, `.claude/commands/opsx/`.

---

## Templates

### Template: Design doc

````markdown
# <module-name> — Design

<Short purpose paragraph: 2-4 sentences. What does this module provision? When should a Terraform practitioner use it? Reference its primary AWS service(s).>

## Architecture

<List the AWS resources the module creates as a bullet list, then 1-2 paragraphs describing how they compose. Where applicable, mention any "one X per Y" cardinality constraints (e.g. "one HTTP API per Lambda — no shared gateway").>

## Components

<For each major resource, a `### <resource_type>` subsection. Include:
- What the resource is and why it exists
- Key inputs that drive it (variable name, type, default, brief purpose) — described inline next to the resource
- Key outputs the resource contributes (if any)
- Any notable design decision affecting this resource (e.g. "image_uri pinned to ECR digest, not tag — see Why-digest below"). Inline the decision and its rationale; do not invent a separate "Decisions" header.>

## Data flow

<1-2 paragraphs describing how a request, event, or trigger traverses the resources at runtime. For trigger modules, describe the event source → Lambda path. For lambda-function, describe the cold-start / invocation lifecycle at a high level. For s3-static-site, describe the request path through CloudFront → S3.>

## Error handling

<Bullet list of:
- Variable validations the module enforces (Terraform `validation { ... }` blocks)
- AWS-side guardrails relied upon (e.g. "AWS rejects allow_origins=['*'] with allow_credentials=true at apply time")
- Known failure modes and how the module surfaces them>

## Testing

<How the module is verified:
- `terraform fmt -check` and `terraform validate` against the module
- Reference any usage examples under `examples/<module-name>/` (check whether they exist; if so, list them; if not, omit)>
````

### Template: Frozen plan

````markdown
# <module-name> — Implementation plan (frozen migration record)

> **Note:** Superpowers plans are normally written for upcoming work. This plan is a frozen record of work already completed, migrated from OpenSpec `tasks.md` files in the now-deleted `openspec/` tree. It is preserved for traceability and is **not intended to be executed** — the corresponding terraform module is already implemented and shipping.

## Tasks

<For each contributing OpenSpec change, a `### From change: <change-name>` subsection containing the full original `tasks.md` content (preserve all `- [x]` checkboxes verbatim, preserve the original numbered task headings like `## 1. Add variable and locals`). If multiple changes contributed, list them in chronological order based on git log of the openspec/changes/<name>/ directory.>

## Verification performed

- `terraform fmt` (formatting check)
- `terraform validate` (provider schema validation)
- Manual usage in `examples/` (if applicable)
````

---

## Task 1: Pre-flight inventory

**Files:**
- Read-only: `openspec/changes/`, `modules/`

- [ ] **Step 1: Confirm target directories exist**

```bash
ls -d /Users/jrsue/dev/repos/terraform-modules/docs/superpowers/specs /Users/jrsue/dev/repos/terraform-modules/docs/superpowers/plans
```

Expected: both paths print without error. (They were created during brainstorming.) If either is missing, run:

```bash
mkdir -p /Users/jrsue/dev/repos/terraform-modules/docs/superpowers/specs /Users/jrsue/dev/repos/terraform-modules/docs/superpowers/plans
```

- [ ] **Step 2: Inventory OpenSpec changes**

```bash
ls /Users/jrsue/dev/repos/terraform-modules/openspec/changes/
```

Expected output (10 entries, one of which is the empty `archive/`):
```
apigw-authorizer
apigw-cors
apigw-disable-default-endpoint
archive
lambda-container-image-support
lambda-modules
lambda-reserved-concurrency
s3-static-site
trigger-sns
trigger-sqs
```

- [ ] **Step 3: Confirm all OpenSpec tasks are complete**

```bash
rtk proxy bash -c 'cd /Users/jrsue/dev/repos/terraform-modules && for d in openspec/changes/*/; do n=$(basename "$d"); if [ -f "$d/tasks.md" ]; then p=$(grep -c "^- \[ \]" "$d/tasks.md"); echo "$n: pending=$p"; fi; done'
```

Expected: every change reports `pending=0`. If any change has `pending` > 0, **stop** and surface to the user — the assumption "all changes complete" is invalidated and the design needs revisiting.

- [ ] **Step 4: Inventory terraform modules**

```bash
ls /Users/jrsue/dev/repos/terraform-modules/modules/
```

Expected: 9 module directories — `lambda-function`, `lambda-trigger-apigw`, `lambda-trigger-cognito`, `lambda-trigger-dynamodb`, `lambda-trigger-s3`, `lambda-trigger-scheduler`, `lambda-trigger-sns`, `lambda-trigger-sqs`, `s3-static-site`.

If the actual list differs from this expected list, **stop** and surface to the user — the design's per-module mapping needs updating.

---

## Task 2: Synthesize `lambda-function`

**Files:**
- Read: `openspec/changes/lambda-modules/proposal.md`, `openspec/changes/lambda-modules/design.md`, `openspec/changes/lambda-modules/tasks.md`, `openspec/changes/lambda-modules/specs/lambda-core/spec.md`
- Read: `openspec/changes/lambda-container-image-support/proposal.md`, `.../design.md`, `.../tasks.md`, `.../specs/lambda-core/spec.md`
- Read: `openspec/changes/lambda-reserved-concurrency/proposal.md`, `.../design.md`, `.../tasks.md`, `.../specs/reserved-concurrency/spec.md`
- Read: every `.tf` file under `modules/lambda-function/`
- Create: `docs/superpowers/specs/2026-05-03-lambda-function-design.md`
- Create: `docs/superpowers/plans/2026-05-03-lambda-function-plan.md`

- [ ] **Step 1: Read all source files**

Use Read on each path listed above. The `lambda-modules` content is the umbrella spec that introduced the core module; `lambda-container-image-support` and `lambda-reserved-concurrency` are layered features added later.

- [ ] **Step 2: Read the module's terraform code**

```bash
ls /Users/jrsue/dev/repos/terraform-modules/modules/lambda-function/
```

Then Read every `.tf` file in that directory. Treat the code as the source of truth for variable names, defaults, validations, and resource arguments.

- [ ] **Step 3: Write the design doc**

Write `docs/superpowers/specs/2026-05-03-lambda-function-design.md` using the **Template: Design doc** above verbatim for structure. Module-specific content guidance:

- **Purpose**: Lambda function + IAM execution role + CloudWatch log group, with optional VPC config, env vars, container or zip packaging, and reserved concurrency.
- **Architecture**: bullet the resources (`aws_lambda_function`, `aws_iam_role`, `aws_iam_role_policy`, `aws_cloudwatch_log_group`, possibly `aws_iam_role_policy_attachment` for VPC). Note BYO-role mode (`existing_role_arn`).
- **Components**: subsections for the function, IAM, log group, packaging modes (zip vs container image), reserved concurrency. Include the `image_uri` ECR-digest decision from the user's CLAUDE.md if it appears in the OpenSpec sources or .tf code.
- **Data flow**: Lambda cold-start / invocation, log emission to CloudWatch.
- **Error handling**: variable validations on `architecture`, `runtime`, `memory_size`; AWS-side limits.
- **Testing**: `terraform fmt`/`validate`; reference `examples/lambda-function/` if present.

- [ ] **Step 4: Write the frozen plan**

Write `docs/superpowers/plans/2026-05-03-lambda-function-plan.md` using **Template: Frozen plan** above. Three contributing changes' `tasks.md` content gets concatenated under three `### From change: <name>` headings, in this order:

1. `### From change: lambda-modules` — but include only the lambda-core-relevant tasks (skip trigger-* tasks; those go to their respective module plans).
2. `### From change: lambda-container-image-support`
3. `### From change: lambda-reserved-concurrency`

Preserve all `- [x]` checkboxes verbatim. Preserve original numbered task headings.

- [ ] **Step 5: Verify both output files exist and are non-empty**

```bash
ls -l /Users/jrsue/dev/repos/terraform-modules/docs/superpowers/specs/2026-05-03-lambda-function-design.md /Users/jrsue/dev/repos/terraform-modules/docs/superpowers/plans/2026-05-03-lambda-function-plan.md
```

Expected: both files exist with size > 1 KB.

---

## Task 3: Synthesize `lambda-trigger-apigw`

**Files:**
- Read: `openspec/changes/lambda-modules/specs/trigger-apigw/spec.md`, plus `lambda-modules` proposal/design/tasks (trigger-apigw-relevant portions only)
- Read: `openspec/changes/apigw-authorizer/{proposal,design,tasks}.md`, `openspec/changes/apigw-authorizer/specs/trigger-apigw/spec.md`
- Read: `openspec/changes/apigw-cors/{proposal,design,tasks}.md`, `openspec/changes/apigw-cors/specs/apigw-cors/spec.md`
- Read: `openspec/changes/apigw-disable-default-endpoint/{proposal,design,tasks}.md`, `openspec/changes/apigw-disable-default-endpoint/specs/disable-default-endpoint/spec.md`
- Read: every `.tf` file under `modules/lambda-trigger-apigw/`
- Create: `docs/superpowers/specs/2026-05-03-lambda-trigger-apigw-design.md`
- Create: `docs/superpowers/plans/2026-05-03-lambda-trigger-apigw-plan.md`

- [ ] **Step 1: Read all source files** (use Read on each path above).

- [ ] **Step 2: Read terraform code** under `modules/lambda-trigger-apigw/`.

- [ ] **Step 3: Write the design doc**

Use **Template: Design doc**. Module-specific content guidance:

- **Purpose**: HTTP API Gateway v2 in front of one Lambda; multi-route support, optional custom domain (Route53 + BYO ACM), optional CORS, optional JWT/Lambda authorizer, optional disabling of the default `*.execute-api.<region>.amazonaws.com` endpoint.
- **Architecture**: bullet `aws_apigatewayv2_api`, `aws_apigatewayv2_integration`, `aws_apigatewayv2_route` (one per route), `aws_apigatewayv2_stage`, `aws_lambda_permission`, optional `aws_apigatewayv2_domain_name` + `aws_apigatewayv2_api_mapping` + `aws_route53_record`, optional `aws_apigatewayv2_authorizer`. State the "one API per Lambda" constraint.
- **Components**: subsections per resource group. Inline these decisions:
  - `cors` variable accepts `null`/`false`/`true`/object (rationale: matches Serverless Framework UX)
  - `custom_domain` is a single object variable (all-or-nothing, no impossible state)
  - `existing_role_arn` style not applicable here (this is a trigger; resource-based perm via `aws_lambda_permission`)
  - `disable_default_endpoint` toggles the auto-generated endpoint when a custom domain is in use
- **Data flow**: client → custom domain (or default endpoint) → APIGW route → Lambda integration → Lambda function.
- **Error handling**: cors variable type validation; AWS-side rejection of `allow_origins=['*']` with `allow_credentials=true`; certificate region requirements (must match API region for v2 regional).
- **Testing**: `terraform fmt`/`validate`; example under `examples/lambda-trigger-apigw/` if present.

- [ ] **Step 4: Write the frozen plan**

Concatenate four `### From change:` sections in order:
1. `lambda-modules` (trigger-apigw-relevant tasks only)
2. `apigw-authorizer`
3. `apigw-cors`
4. `apigw-disable-default-endpoint`

- [ ] **Step 5: Verify both files exist and are > 1 KB.**

---

## Task 4: Synthesize `lambda-trigger-cognito`

**Files:**
- Read: `openspec/changes/lambda-modules/specs/trigger-cognito/spec.md` + lambda-modules proposal/design/tasks (trigger-cognito-relevant portions only)
- Read: every `.tf` file under `modules/lambda-trigger-cognito/`
- Create: `docs/superpowers/specs/2026-05-03-lambda-trigger-cognito-design.md`
- Create: `docs/superpowers/plans/2026-05-03-lambda-trigger-cognito-plan.md`

- [ ] **Step 1: Read sources** (use Read on each path above).
- [ ] **Step 2: Read terraform code** under `modules/lambda-trigger-cognito/`.
- [ ] **Step 3: Write the design doc** using **Template: Design doc**. Module guidance: wires a Lambda as a Cognito User Pool trigger (pre-sign-up, post-confirmation, pre-token-generation, etc.). Resources: `aws_cognito_user_pool` lambda_config update + `aws_lambda_permission`. No role-based IAM (resource-based perm).
- [ ] **Step 4: Write the frozen plan** with one `### From change: lambda-modules` section containing the trigger-cognito-relevant tasks only.
- [ ] **Step 5: Verify both files exist and are > 1 KB.**

---

## Task 5: Synthesize `lambda-trigger-dynamodb`

**Files:**
- Read: `openspec/changes/lambda-modules/specs/trigger-dynamodb/spec.md` + lambda-modules proposal/design/tasks (trigger-dynamodb-relevant portions)
- Read: every `.tf` file under `modules/lambda-trigger-dynamodb/`
- Create: `docs/superpowers/specs/2026-05-03-lambda-trigger-dynamodb-design.md`
- Create: `docs/superpowers/plans/2026-05-03-lambda-trigger-dynamodb-plan.md`

- [ ] **Step 1: Read sources.**
- [ ] **Step 2: Read terraform code** under `modules/lambda-trigger-dynamodb/`.
- [ ] **Step 3: Write the design doc** using **Template: Design doc**. Module guidance: DynamoDB stream event source mapping → Lambda. Resources: `aws_lambda_event_source_mapping` + `aws_iam_role_policy` (attached to the Lambda's execution role for stream read access). Inline the IAM decision: trigger module accepts `role_name` and attaches the policy itself (rationale from lambda-modules design.md). Include filtering and batch configuration.
- [ ] **Step 4: Write the frozen plan** with `### From change: lambda-modules` containing trigger-dynamodb-relevant tasks.
- [ ] **Step 5: Verify both files exist and are > 1 KB.**

---

## Task 6: Synthesize `lambda-trigger-s3`

**Files:**
- Read: `openspec/changes/lambda-modules/specs/trigger-s3/spec.md` + lambda-modules proposal/design/tasks (trigger-s3-relevant portions)
- Read: every `.tf` file under `modules/lambda-trigger-s3/`
- Create: `docs/superpowers/specs/2026-05-03-lambda-trigger-s3-design.md`
- Create: `docs/superpowers/plans/2026-05-03-lambda-trigger-s3-plan.md`

- [ ] **Step 1: Read sources.**
- [ ] **Step 2: Read terraform code** under `modules/lambda-trigger-s3/`.
- [ ] **Step 3: Write the design doc** using **Template: Design doc**. Module guidance: S3 bucket notifications → Lambda, with event type / prefix / suffix filtering. Resources: `aws_s3_bucket_notification` + `aws_lambda_permission`. Resource-based IAM (no `role_name`).
- [ ] **Step 4: Write the frozen plan** with `### From change: lambda-modules` containing trigger-s3-relevant tasks.
- [ ] **Step 5: Verify both files exist and are > 1 KB.**

---

## Task 7: Synthesize `lambda-trigger-scheduler` (code-only)

**Files:**
- Read: every `.tf` file under `modules/lambda-trigger-scheduler/`
- Read: relevant commit message — `git show cc2bc86 --stat` for context on when/why the module was added
- Create: `docs/superpowers/specs/2026-05-03-lambda-trigger-scheduler-design.md`
- Create: `docs/superpowers/plans/2026-05-03-lambda-trigger-scheduler-plan.md`

This module has **no OpenSpec source content**. The design is synthesized from the terraform code only and will be thinner on rationale than the others — that is acceptable per the spec.

- [ ] **Step 1: Read terraform code** under `modules/lambda-trigger-scheduler/`.

- [ ] **Step 2: Capture historical context from git**

```bash
git -C /Users/jrsue/dev/repos/terraform-modules show cc2bc86 --stat
git -C /Users/jrsue/dev/repos/terraform-modules log --oneline -- modules/lambda-trigger-scheduler/
```

Use the commit messages and diff to inform the Purpose paragraph and any decisions worth surfacing.

- [ ] **Step 3: Write the design doc** using **Template: Design doc**. Module guidance: EventBridge Scheduler schedule → Lambda. Resources: `aws_scheduler_schedule` (and possibly `aws_scheduler_schedule_group`) + `aws_iam_role` for the scheduler to assume + `aws_iam_role_policy` granting `lambda:InvokeFunction` + `aws_lambda_permission` (or a role-based path, depending on what the .tf actually does — read first, then write accordingly). If rationale for a particular choice is unclear from the code alone, omit it rather than guessing — the doc can be enriched later if the user has context to add.

- [ ] **Step 4: Write the frozen plan**

Since there is no source `tasks.md`, the plan body uses a single section:

```markdown
## Tasks

### From git history

This module was added without an OpenSpec change. See git log for `modules/lambda-trigger-scheduler/`. The work is complete; no checklist was authored at the time.

## Verification performed

- `terraform fmt` and `terraform validate` (per the user's CLAUDE.md convention)
- Module is shipping in the current `master` branch.
```

- [ ] **Step 5: Verify both files exist and are > 0.5 KB** (this one is allowed to be smaller because it has no OpenSpec source).

---

## Task 8: Synthesize `lambda-trigger-sns`

**Files:**
- Read: `openspec/changes/trigger-sns/{proposal,design,tasks}.md`, `openspec/changes/trigger-sns/specs/trigger-sns/spec.md`
- Read: every `.tf` file under `modules/lambda-trigger-sns/`
- Create: `docs/superpowers/specs/2026-05-03-lambda-trigger-sns-design.md`
- Create: `docs/superpowers/plans/2026-05-03-lambda-trigger-sns-plan.md`

- [ ] **Step 1: Read sources.**
- [ ] **Step 2: Read terraform code** under `modules/lambda-trigger-sns/`.
- [ ] **Step 3: Write the design doc** using **Template: Design doc**. Module guidance: SNS topic subscription → Lambda. Resources: `aws_sns_topic_subscription` + `aws_lambda_permission`. Resource-based IAM.
- [ ] **Step 4: Write the frozen plan** with one `### From change: trigger-sns` section containing the change's full tasks.md.
- [ ] **Step 5: Verify both files exist and are > 1 KB.**

---

## Task 9: Synthesize `lambda-trigger-sqs`

**Files:**
- Read: `openspec/changes/trigger-sqs/{proposal,design,tasks}.md`, `openspec/changes/trigger-sqs/specs/trigger-sqs/spec.md`
- Read: every `.tf` file under `modules/lambda-trigger-sqs/`
- Create: `docs/superpowers/specs/2026-05-03-lambda-trigger-sqs-design.md`
- Create: `docs/superpowers/plans/2026-05-03-lambda-trigger-sqs-plan.md`

- [ ] **Step 1: Read sources.**
- [ ] **Step 2: Read terraform code** under `modules/lambda-trigger-sqs/`.
- [ ] **Step 3: Write the design doc** using **Template: Design doc**. Module guidance: SQS event source mapping → Lambda. Resources: `aws_lambda_event_source_mapping` + `aws_iam_role_policy` (attached to the Lambda's execution role for queue read access). Like DynamoDB, this is a role-based trigger and accepts `role_name`.
- [ ] **Step 4: Write the frozen plan** with one `### From change: trigger-sqs` section.
- [ ] **Step 5: Verify both files exist and are > 1 KB.**

---

## Task 10: Synthesize `s3-static-site`

**Files:**
- Read: `openspec/changes/s3-static-site/{proposal,design,tasks}.md`, `openspec/changes/s3-static-site/specs/s3-static-site/spec.md`
- Read: every `.tf` file under `modules/s3-static-site/`
- Create: `docs/superpowers/specs/2026-05-03-s3-static-site-design.md`
- Create: `docs/superpowers/plans/2026-05-03-s3-static-site-plan.md`

- [ ] **Step 1: Read sources.**
- [ ] **Step 2: Read terraform code** under `modules/s3-static-site/`.
- [ ] **Step 3: Write the design doc** using **Template: Design doc**. Module guidance: static site hosted on S3, fronted by CloudFront, with optional Route53 alias and ACM certificate. Resources will include `aws_s3_bucket` (with `force_destroy = true` per CLAUDE.md), bucket policy, `aws_cloudfront_distribution`, `aws_cloudfront_origin_access_control` (or OAI), optionally `aws_route53_record` and ACM bindings. Inline the `force_destroy = true` decision since it is a documented user convention.
- [ ] **Step 4: Write the frozen plan** with one `### From change: s3-static-site` section.
- [ ] **Step 5: Verify both files exist and are > 1 KB.**

---

## Task 11: Cross-module verification

**Files:**
- Read-only: all 9 design docs and 9 frozen plans created in Tasks 2-10

- [ ] **Step 1: Confirm all 18 output files exist**

```bash
rtk proxy bash -c 'cd /Users/jrsue/dev/repos/terraform-modules && for m in lambda-function lambda-trigger-apigw lambda-trigger-cognito lambda-trigger-dynamodb lambda-trigger-s3 lambda-trigger-scheduler lambda-trigger-sns lambda-trigger-sqs s3-static-site; do for k in design plan; do f="docs/superpowers/$([ $k = design ] && echo specs || echo plans)/2026-05-03-$m-$k.md"; if [ -f "$f" ]; then echo "ok: $f"; else echo "MISSING: $f"; fi; done; done'
```

Expected: 18 lines, all starting with `ok:`. Any `MISSING:` line means the corresponding synthesis task was not actually completed — return to that task before proceeding.

- [ ] **Step 2: Section-structure check on every design**

```bash
rtk proxy bash -c 'cd /Users/jrsue/dev/repos/terraform-modules && for f in docs/superpowers/specs/2026-05-03-*-design.md; do echo "=== $f ==="; grep -E "^## (Architecture|Components|Data flow|Error handling|Testing)$" "$f" | sort -u; done'
```

Expected: every file lists exactly the five canonical headers. Any file missing a header → fix it.

(Note: the conversion-itself design doc already in `specs/` will also appear; verify it has the same five headers — it should, since brainstorming wrote it that way.)

- [ ] **Step 3: Disclaimer check on every frozen plan**

```bash
rtk proxy bash -c 'cd /Users/jrsue/dev/repos/terraform-modules && for f in docs/superpowers/plans/2026-05-03-*-plan.md; do if ! grep -q "frozen migration record" "$f"; then echo "MISSING disclaimer: $f"; fi; done'
```

Expected: no output. Any line means the file is missing the frozen-record disclaimer header.

- [ ] **Step 4: Spot-check 3 designs against OpenSpec sources for missing decisions**

Pick 3 of the 9 modules at random (e.g. `lambda-trigger-apigw`, `lambda-function`, `s3-static-site`). For each:
1. Read the OpenSpec `design.md` files contributing to it.
2. Read the synthesized design doc.
3. List every "Decision" or "Rationale" subsection in the OpenSpec source.
4. For each, confirm the decision is reflected (anywhere) in the synthesized doc — usually under Components or Architecture as inline rationale.
5. If a decision is missing, add it to the appropriate section of the synthesized doc.

This is manual; there is no command to automate it. Plan ~5 minutes per module.

- [ ] **Step 5: Code-vs-doc sanity check on 1 module**

Pick `lambda-trigger-apigw`. List all variables in `modules/lambda-trigger-apigw/variables.tf`:

```bash
rtk proxy bash -c 'grep -h "^variable " /Users/jrsue/dev/repos/terraform-modules/modules/lambda-trigger-apigw/*.tf | sort -u'
```

Confirm every variable name appears somewhere in the synthesized design doc. If a variable is missing from the doc, add it to the relevant Component subsection.

(This check is only run on one module as a sanity probe — not all 9 — to keep the plan tractable.)

---

## Task 12: Teardown — delete OpenSpec artifacts

**Files:**
- Delete: `openspec/` (entire tree)
- Delete: `.claude/skills/openspec-propose/`, `openspec-explore/`, `openspec-apply-change/`, `openspec-archive-change/`
- Delete: `.claude/commands/opsx/`

- [ ] **Step 1: Re-confirm the verification passed**

Before any deletion, confirm Task 11 completed with no `MISSING:` outputs and the spot-check found no dropped decisions. If unsure, stop and surface to the user.

- [ ] **Step 2: Delete the openspec tree**

```bash
rm -rf /Users/jrsue/dev/repos/terraform-modules/openspec
```

- [ ] **Step 3: Delete the openspec skills**

```bash
rm -rf /Users/jrsue/dev/repos/terraform-modules/.claude/skills/openspec-propose /Users/jrsue/dev/repos/terraform-modules/.claude/skills/openspec-explore /Users/jrsue/dev/repos/terraform-modules/.claude/skills/openspec-apply-change /Users/jrsue/dev/repos/terraform-modules/.claude/skills/openspec-archive-change
```

- [ ] **Step 4: Delete the opsx slash-command folder**

```bash
rm -rf /Users/jrsue/dev/repos/terraform-modules/.claude/commands/opsx
```

- [ ] **Step 5: Confirm deletions**

```bash
ls /Users/jrsue/dev/repos/terraform-modules/openspec 2>&1
ls /Users/jrsue/dev/repos/terraform-modules/.claude/skills/
ls /Users/jrsue/dev/repos/terraform-modules/.claude/commands/
```

Expected:
- First `ls`: error "No such file or directory" (the tree is gone).
- Second `ls`: no `openspec-*` entries remain.
- Third `ls`: no `opsx` entry remains.

---

## Task 13: Final post-teardown checks

**Files:** read-only across the repo.

- [ ] **Step 1: Stale-reference grep**

```bash
rtk proxy bash -c 'cd /Users/jrsue/dev/repos/terraform-modules && grep -RIn --exclude-dir=.git --exclude-dir=.terraform --exclude-dir=docs -E "openspec|opsx" . || echo "no stale references"'
```

Expected: `no stale references`. The `--exclude-dir=docs` is intentional — the new design doc legitimately references "OpenSpec" as the prior framework being replaced; that is allowed.

If references appear in `modules/`, `examples/`, `README.md`, `.gitignore`, or `versions.tf`, fix or remove them. (None are expected, but the grep is the safety net.)

- [ ] **Step 2: Terraform sanity check**

```bash
rtk proxy bash -c 'cd /Users/jrsue/dev/repos/terraform-modules && terraform fmt -check -recursive modules/'
```

Expected: exit 0, no output. (We did not touch `.tf` files; this is a pure safety net to confirm no accidental damage.)

- [ ] **Step 3: README check**

```bash
grep -n -E "openspec|opsx|OpenSpec" /Users/jrsue/dev/repos/terraform-modules/README.md
```

If the README references OpenSpec or opsx, surface the matches to the user — they may want to update README to reference the new `docs/superpowers/` layout. This is **not** auto-fixed by this plan; it is flagged for user decision.

---

## Task 14: Commit (gated on user approval)

**Files:** all changes from Tasks 2-12.

> **Hard gate:** The user's global instruction is "Never commit or push automatically". This task **must not run** until the user explicitly says "commit it" (or equivalent). If executing via subagent or executing-plans, **stop here** and surface the diff to the user before proceeding.

- [ ] **Step 1: Show the user what will be committed**

```bash
git -C /Users/jrsue/dev/repos/terraform-modules status
git -C /Users/jrsue/dev/repos/terraform-modules diff --stat
```

Expected: 18 new files under `docs/superpowers/`, 1 deleted tree (`openspec/`), 4 deleted skill dirs, 1 deleted commands dir.

- [ ] **Step 2: Wait for user approval.**

Do not proceed without an explicit go-ahead.

- [ ] **Step 3: Stage**

```bash
git -C /Users/jrsue/dev/repos/terraform-modules add docs/superpowers .claude/skills .claude/commands openspec
```

(Listing each path explicitly avoids accidentally staging other unrelated changes; `git add` on deleted paths records the deletions.)

- [ ] **Step 4: Commit**

```bash
git -C /Users/jrsue/dev/repos/terraform-modules commit -m "$(cat <<'EOF'
chore: replace OpenSpec with superpowers per-module designs

Synthesize 9 per-module design docs and 9 frozen plan docs under
docs/superpowers/ from the existing OpenSpec sources, then remove the
openspec/ tree, the four openspec-* skills, and the opsx slash-command
folder. Spec at docs/superpowers/specs/2026-05-03-openspec-to-superpowers-design.md.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 5: Verify**

```bash
git -C /Users/jrsue/dev/repos/terraform-modules log -1 --stat
git -C /Users/jrsue/dev/repos/terraform-modules status
```

Expected: one new commit with the new files added and the openspec/skills/commands deletions; working tree clean.

---

## Summary checklist

- [ ] Task 1: Pre-flight inventory
- [ ] Task 2: Synthesize lambda-function
- [ ] Task 3: Synthesize lambda-trigger-apigw
- [ ] Task 4: Synthesize lambda-trigger-cognito
- [ ] Task 5: Synthesize lambda-trigger-dynamodb
- [ ] Task 6: Synthesize lambda-trigger-s3
- [ ] Task 7: Synthesize lambda-trigger-scheduler (code-only)
- [ ] Task 8: Synthesize lambda-trigger-sns
- [ ] Task 9: Synthesize lambda-trigger-sqs
- [ ] Task 10: Synthesize s3-static-site
- [ ] Task 11: Cross-module verification
- [ ] Task 12: Teardown — delete OpenSpec artifacts
- [ ] Task 13: Final post-teardown checks
- [ ] Task 14: Commit (gated on user approval)
