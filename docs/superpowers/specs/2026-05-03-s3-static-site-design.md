# s3-static-site — Design

This module provisions a complete static website hosting stack on AWS: a private S3 bucket for object storage fronted by a CloudFront distribution for CDN delivery and HTTPS termination. It is the right choice when a Terraform practitioner needs to host a single-page application, documentation site, or marketing site with optional custom domain support. Primary AWS services are Amazon S3, Amazon CloudFront, and optionally Amazon Route 53.

## Architecture

The module creates the following AWS resources:

- `aws_s3_bucket` — private object store for static assets (`force_destroy = true`)
- `aws_s3_bucket_public_access_block` — blocks all public access to the bucket
- `aws_s3_bucket_policy` — IAM policy restricting `s3:GetObject` to the CloudFront distribution via OAC condition
- `aws_cloudfront_origin_access_control` — OAC that signs requests from CloudFront to S3 using SigV4
- `aws_cloudfront_distribution` — CDN distribution with the S3 bucket as its sole origin
- `aws_route53_record` (A, IPv4) — optional alias record pointing the custom domain to the distribution
- `aws_route53_record` (AAAA, IPv6) — optional alias record for dual-stack support

The S3 bucket is never publicly accessible. CloudFront is the single point of ingress: it authenticates each origin fetch using Origin Access Control, which signs requests with SigV4 and scopes them to the specific distribution ARN in the bucket policy. The CloudFront distribution uses the AWS-managed `CachingOptimized` cache policy by default and redirects all HTTP traffic to HTTPS. When `custom_domain` is provided, the distribution gains an alias, an ACM certificate is attached, and both IPv4 and IPv6 Route 53 alias records are created.

## Components

### aws_s3_bucket

The private object store that holds all static assets. Named using `var.site_name`.

- `site_name` (string, required) — used as the bucket name and as the `origin_id` in the CloudFront distribution.
- `tags` (map(string), default `{}`) — propagated to all taggable resources.
- `force_destroy = true` — allows `terraform destroy` to succeed even when the bucket contains objects. Project convention: static asset buckets contain no user-generated data and must tear down cleanly in dev/staging environments.

Outputs contributed: `bucket_name`, `bucket_arn`.

### aws_s3_bucket_public_access_block

Sets all four public-access block settings (`block_public_acls`, `block_public_policy`, `ignore_public_acls`, `restrict_public_buckets`) to `true`. The bucket policy is applied with an explicit `depends_on` on this resource to avoid a race condition where the policy evaluation is attempted before public access block settings are active.

### aws_s3_bucket_policy (data.aws_iam_policy_document)

Grants `s3:GetObject` on all objects in the bucket to `cloudfront.amazonaws.com`, but only when the request carries an `AWS:SourceArn` condition matching the specific CloudFront distribution ARN. This restricts access to exactly this distribution — other CloudFront distributions cannot access the bucket even with a valid OAC.

### aws_cloudfront_origin_access_control

Signs every CloudFront-to-S3 fetch with SigV4 (`signing_protocol = "sigv4"`, `signing_behavior = "always"`). Named using `var.site_name`.

Design decision — OAC over OAI: The module uses `aws_cloudfront_origin_access_control` rather than the legacy `aws_cloudfront_origin_access_identity`. OAC is the AWS-recommended approach since 2022, supports SSE-KMS encrypted buckets, and is the only path being actively maintained. OAI does not support SSE-KMS and is considered legacy.

### aws_cloudfront_distribution

The CDN layer. Key inputs:

- `index_document` (string, default `"index.html"`) — set as the `default_root_object`; also used as the SPA error-response target path.
- `error_document` (string, default `"error.html"`) — documented for non-SPA mode reference; not directly wired into a CloudFront property (CloudFront itself does not have an error-document concept equivalent to S3 static hosting).
- `spa_mode` (bool, default `true`) — when `true`, injects a `custom_error_response` block that maps HTTP 403 responses from S3 to `/${var.index_document}` with status 200. SPAs using client-side routing (React Router, Vue Router, etc.) need all deep-link paths to return `index.html`; without this, S3 returns 403 for any path that is not a stored key, and the user sees an error page. Set `false` for multi-page sites or documentation generators that produce one HTML file per route.
- `cache_policy_id` (string, default `"658327ea-f89d-4fab-a63d-7e88639e58f6"` — AWS managed `CachingOptimized`) — allows overriding the cache policy when different TTL or compression settings are needed.
- `origin_request_policy_id` (string, default `"88a5eaf4-2f7a-4b3b-b694-47856e546348"` — AWS managed `CORS-S3Origin`) — passes CORS-related headers to the S3 origin.
- `price_class` (string, default `"PriceClass_100"`) — controls which CloudFront edge locations serve traffic. `PriceClass_100` covers North America and Europe; change to `PriceClass_All` for global coverage.
- `custom_domain` — see `aws_route53_record` section below. When provided, `aliases` is set and the `viewer_certificate` block uses the ACM certificate with `sni-only` SSL and minimum TLS 1.2 (`TLSv1.2_2021`). When null, the CloudFront default certificate is used.

Outputs contributed: `distribution_id`, `distribution_domain_name`, `site_url`.

### aws_route53_record (A and AAAA)

Created only when `custom_domain != null`. Both IPv4 (A) and IPv6 (AAAA) alias records are created in the provided hosted zone, pointing to the CloudFront distribution's domain name and hosted zone ID. `evaluate_target_health = false` is set — CloudFront distributions do not support health-check-based routing.

Custom domain variable:

```hcl
variable "custom_domain" {
  type = object({
    domain_name     = string   # e.g. "www.example.com"
    hosted_zone_id  = string   # Route 53 hosted zone ID
    certificate_arn = string   # ACM certificate ARN (must be in us-east-1)
  })
  default = null
}
```

Design decision — null default / all-or-nothing: The custom domain is an optional object following the same pattern used by `lambda-trigger-apigw`. Either all three fields are provided and the full domain stack is created, or the feature is omitted entirely. Partial configuration is not possible, which keeps the conditional logic (`local.create_domain`) simple.

## Data flow

A viewer request arrives at a CloudFront edge location. CloudFront checks its cache; on a miss it signs a `GET` request to the S3 bucket's regional domain name using SigV4 (via the OAC), fetching the object. The bucket policy validates that the `AWS:SourceArn` matches this distribution before allowing the read. CloudFront caches the response at the edge (subject to the `CachingOptimized` policy TTLs) and returns it to the viewer over HTTPS. Subsequent requests for the same object are served from the edge cache without hitting S3.

When a viewer navigates directly to a deep-link path (e.g., `/dashboard/settings`) that does not correspond to a stored S3 key, S3 returns 403. With `spa_mode = true`, CloudFront's custom error response intercepts the 403 and serves `/index.html` with HTTP 200 instead, allowing the SPA's client-side router to handle the path.

## Error handling

- No Terraform `validation { }` blocks are present in `variables.tf` — the module relies on AWS API errors for invalid inputs. In particular, if `custom_domain.certificate_arn` references a certificate outside `us-east-1`, the CloudFront API returns a descriptive error (`InvalidViewerCertificate`); the module documents this requirement in the README rather than replicating the validation in Terraform.
- `aws_s3_bucket_public_access_block` with all four settings `true` ensures no misconfigured bucket ACL or policy can accidentally expose objects publicly.
- The `depends_on` from `aws_s3_bucket_policy` to `aws_s3_bucket_public_access_block` prevents the policy from being applied before the public access block is enforced, avoiding a brief window of potential public access.
- `force_destroy = true` is intentional: static asset buckets contain no user-generated data, and the flag is required for clean `terraform destroy` in CI and non-production environments.
- Bucket name uniqueness is a global S3 constraint — `var.site_name` must be globally unique. No Terraform validation enforces this; the S3 API returns a `BucketAlreadyExists` or `BucketAlreadyOwnedByYou` error.

## Testing

The module is verified by:

- `terraform fmt -check` on all files under `modules/s3-static-site/`
- `terraform validate` against the module (requires `terraform init` with AWS provider)
- A usage example is provided at `examples/static-site/main.tf` demonstrating `site_name`, `custom_domain`, SPA mode, and the key module outputs (`site_url`, `bucket_name`, `distribution_id`)
