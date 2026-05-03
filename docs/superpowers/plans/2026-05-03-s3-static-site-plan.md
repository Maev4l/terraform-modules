# s3-static-site — Implementation plan (frozen migration record)

> **Note:** Superpowers plans are normally written for upcoming work. This plan is a frozen record of work already completed, migrated from OpenSpec `tasks.md` files in the now-deleted `openspec/` tree. It is preserved for traceability and is **not intended to be executed** — the corresponding terraform module is already implemented and shipping.

## Tasks

### From change: s3-static-site

## 1. Create module structure

- [x] 1.1 Create `modules/s3-static-site/variables.tf` with: `site_name`, `index_document`, `error_document`, `spa_mode`, `cache_policy_id`, `custom_domain`, `tags`
- [x] 1.2 Create `modules/s3-static-site/versions.tf` with required provider

## 2. S3 bucket

- [x] 2.1 Create `modules/s3-static-site/main.tf` with S3 bucket, public access block (all four settings true), and bucket policy allowing `s3:GetObject` from CloudFront OAC only

## 3. CloudFront distribution

- [x] 3.1 Create `modules/s3-static-site/cloudfront.tf` with Origin Access Control, CloudFront distribution (S3 origin, CachingOptimized default cache policy, configurable `cache_policy_id`, default root object, conditional SPA custom error response), optional custom domain alias with Route53 A-record

## 4. Outputs

- [x] 4.1 Create `modules/s3-static-site/outputs.tf` exposing `bucket_name`, `bucket_arn`, `distribution_id`, `distribution_domain_name`, `site_url`

## 5. Documentation

- [x] 5.1 Create `modules/s3-static-site/README.md` with exhaustive input/output documentation and ACM certificate region note

## 6. Example

- [x] 6.1 Create `examples/static-site/main.tf` demonstrating the module with custom domain

## 7. Root README

- [x] 7.1 Update root `README.md` to remove "coming soon" from the s3-static-site entry and add the static-site example

## 8. Validation

- [x] 8.1 Run `terraform fmt -recursive` on new files

## Verification performed

- `terraform fmt` (formatting check)
- `terraform validate` (provider schema validation)
- Manual usage in `examples/static-site/` (applicable — example provided)
