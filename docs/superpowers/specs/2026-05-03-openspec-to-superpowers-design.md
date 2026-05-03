# OpenSpec → Superpowers conversion — Design

This repo currently uses the OpenSpec CLI/framework to author module specs and changes under `openspec/`. We are switching to the superpowers skill family (brainstorming → writing-plans → executing-plans). All 9 OpenSpec changes are 100% complete and the corresponding terraform modules are implemented. The conversion produces per-module superpowers design + frozen plan documents synthesized from OpenSpec sources and the module code, then removes OpenSpec entirely (artifacts, skills, slash commands).

## Architecture

The new layout has two top-level folders under `docs/superpowers/`:

- `specs/` — one design doc per terraform module, capturing the **current cumulative state** of the module (not a per-change proposal).
- `plans/` — one frozen plan per module, capturing the historical implementation work that was done. Plans are non-idiomatic for completed work; they are kept as a migration record only and explicitly labeled as such.

Filenames are date-prefixed per the superpowers default: `2026-05-03-<module>-design.md` and `2026-05-03-<module>-plan.md`. The date reflects the day the docs were authored (today), not the original implementation date — this is consistent with the superpowers convention where the prefix reflects when the design was *written*.

The 9 target modules are: `lambda-function`, `lambda-trigger-apigw`, `lambda-trigger-cognito`, `lambda-trigger-dynamodb`, `lambda-trigger-s3`, `lambda-trigger-scheduler`, `lambda-trigger-sns`, `lambda-trigger-sqs`, `s3-static-site`.

After conversion, OpenSpec is fully removed: `openspec/` tree, four `.claude/skills/openspec-*` skills, and the `.claude/commands/opsx/` slash-command folder all delete in the same effort.

## Components

### Per-module design doc

Each design doc follows the superpowers brainstorming canonical sections (architecture, components, data flow, error handling, testing) preceded by a short purpose paragraph. Inputs/outputs and key design decisions are folded into the relevant canonical sections rather than getting their own headers.

```markdown
# <module> — Design

<Short purpose paragraph: what the module provisions, when to use it.>

## Architecture
AWS resources created, how they compose, top-level shape of the module.

## Components
Per-resource breakdown. Variables (name, type, default, purpose) and outputs are
described inline next to the resource that consumes them. Notable design
decisions (e.g. "cors variable accepts bool|object", "image_uri pinned to ECR
digest") are captured as subsections under the relevant component, with the
rationale extracted from OpenSpec design.md files.

## Data flow
How a request, event, or trigger traverses the resources at runtime.

## Error handling
Variable validations, AWS-side guardrails, known failure modes.

## Testing
How the module is verified — `terraform fmt`, `terraform validate`, usage in
`examples/`.
```

### Per-module frozen plan

```markdown
# <module> — Implementation plan (frozen migration record)

> Note: superpowers plans are normally written for upcoming work. This plan is
> a frozen record of work already completed, migrated from OpenSpec tasks.md
> files. It is preserved for traceability and is not intended to be executed.

## Tasks
Consolidated checklist from each contributing OpenSpec change, all [x]. Grouped
by source change so each task remains traceable to the proposal that introduced
it.

## Verification performed
terraform fmt, terraform validate, usage in examples/.
```

### Source-to-target mapping

The umbrella `lambda-modules` change contributed capability specs for several modules. Per-feature changes layered on top. `lambda-trigger-scheduler` had no OpenSpec coverage and is synthesized from code only.

| Target module | OpenSpec inputs | Code input |
|---|---|---|
| `lambda-function` | `lambda-modules` (lambda-core spec, plus lambda-core portions of design.md/tasks.md) + `lambda-container-image-support` + `lambda-reserved-concurrency` | `modules/lambda-function/*.tf` |
| `lambda-trigger-apigw` | `lambda-modules` (trigger-apigw spec) + `apigw-authorizer` + `apigw-cors` + `apigw-disable-default-endpoint` | `modules/lambda-trigger-apigw/*.tf` |
| `lambda-trigger-cognito` | `lambda-modules` (trigger-cognito spec) | `modules/lambda-trigger-cognito/*.tf` |
| `lambda-trigger-dynamodb` | `lambda-modules` (trigger-dynamodb spec) | `modules/lambda-trigger-dynamodb/*.tf` |
| `lambda-trigger-s3` | `lambda-modules` (trigger-s3 spec) | `modules/lambda-trigger-s3/*.tf` |
| `lambda-trigger-scheduler` | (none) | `modules/lambda-trigger-scheduler/*.tf` only |
| `lambda-trigger-sns` | `trigger-sns` | `modules/lambda-trigger-sns/*.tf` |
| `lambda-trigger-sqs` | `trigger-sqs` | `modules/lambda-trigger-sqs/*.tf` |
| `s3-static-site` | `s3-static-site` | `modules/s3-static-site/*.tf` |

## Data flow

Synthesis is a one-shot pipeline run once per module:

1. Load every OpenSpec source listed in the mapping (proposal.md, design.md, tasks.md, specs/<cap>/spec.md).
2. Read the module's `.tf` files to ground the doc in the actual variable names, defaults, resource arguments, and validations as currently shipped.
3. Resolve discrepancies in favor of the code (it is the source of truth; OpenSpec content is supporting context).
4. Write the design doc into the canonical 5-section structure, folding decisions and inputs/outputs inline.
5. Write the frozen plan by concatenating each contributing change's `tasks.md`, grouped under that change's name as a sub-heading, all checkboxes preserved as `[x]`.

After all 18 files (9 designs + 9 plans) are produced and visually verified, the OpenSpec tree and supporting skills/commands are deleted in a single commit alongside the new files.

## Error handling

Risks specific to this conversion:

- **Lossy synthesis** — squashing per-change history into per-module docs loses some "why we did X at time Y" context. Mitigation: the frozen plans group tasks by source change, preserving provenance.
- **Code/spec drift** — OpenSpec content can lag behind the code. Mitigation: code wins on conflict; the visual-verification step (between synthesis and deletion, see Data flow) catches obvious omissions before deletion.
- **Premature deletion** — deleting `openspec/` before verification would lose source material irreversibly (git history aside). Mitigation: verification gate before any `rm`; deletions and additions land in the same commit so a single revert restores the previous state.
- **Scheduler has no OpenSpec source** — its design is synthesized from code only and may be thinner on rationale. Acceptable; the rationale can be added later if needed.

## Testing

There is no automated test for this conversion — it produces documentation. Verification is manual:

- Each design doc has all 5 canonical sections plus a purpose paragraph.
- Each frozen plan carries the disclaimer header and groups tasks by source change.
- Spot-check 2-3 designs against their OpenSpec sources to confirm no decision was dropped.
- After teardown, confirm the repo still passes `terraform fmt -check` and `terraform validate` on the modules (no doc change should affect these, but it's a free safety net).
- Confirm `.claude/skills/` and `.claude/commands/` no longer reference openspec/opsx.
