<!-- Edited by CLAUDE -->

# s3-static-site

Creates a static website hosting stack: private S3 bucket, CloudFront distribution with Origin Access Control, and optional custom domain with Route53. Supports SPA routing out of the box.

## Usage

```hcl
module "website" {
  source = "../../modules/s3-static-site"

  site_name = "my-app-website"

  tags = {
    Team = "frontend"
  }
}
```

After applying, upload your site content:

```bash
aws s3 sync ./dist s3://my-app-website
```

## Architecture

```
Client → CloudFront (HTTPS) → Origin Access Control → S3 (private)
                ↑
         Route53 A-record (optional)
```

- The S3 bucket has **all public access blocked**. Content is served exclusively through CloudFront.
- **Origin Access Control (OAC)** is the modern, AWS-recommended method for securing S3 origins (replaces legacy OAI).
- The bucket policy only allows `s3:GetObject` from the specific CloudFront distribution.

## Inputs

### Required

| Name | Type | Description |
|------|------|-------------|
| `site_name` | `string` | Name for the static site. Used as the S3 bucket name and CloudFront OAC name. Must be globally unique (S3 bucket naming rules). |

### Optional: Content

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `index_document` | `string` | `"index.html"` | The default document served at the root path. Also used as the SPA fallback page. |
| `error_document` | `string` | `"error.html"` | The error document for non-SPA error responses. |
| `spa_mode` | `bool` | `true` | Enable SPA routing. When `true`, 403 errors (missing S3 keys) return the `index_document` with HTTP 200, allowing client-side routers (React Router, Vue Router, etc.) to handle the path. Set to `false` for multi-page sites or documentation where each path maps to a real file. |

### Optional: CloudFront

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cache_policy_id` | `string` | `"658327ea-f89d-4fab-a63d-7e88639e58f6"` | CloudFront cache policy ID. Defaults to the AWS managed **CachingOptimized** policy (gzip/brotli compression, query string forwarding). Other common managed policies: `"4135ea2d-6df8-44a3-9df3-4b5a84be39ad"` (CachingDisabled), `"b2884449-e4de-46a7-ac36-70bc7f1ddd6d"` (CachingOptimizedForUncompressedObjects). |
| `origin_request_policy_id` | `string` | `"88a5eaf4-2f7a-4b3b-b694-47856e546348"` | CloudFront origin request policy ID. Defaults to the AWS managed **CORS-S3Origin** policy (forwards `Origin`, `Access-Control-Request-Headers`, `Access-Control-Request-Method` headers to S3). Needed for cross-origin requests (fonts, API calls from subdomains). Other common managed policies: `"216adef6-5c7f-47e4-b989-5492eafa07d3"` (AllViewer). |
| `price_class` | `string` | `"PriceClass_100"` | CloudFront price class determining which edge locations are used. Possible values: `"PriceClass_100"` (US, Canada, Europe — cheapest), `"PriceClass_200"` (adds Asia, Middle East, Africa), `"PriceClass_All"` (all edge locations globally — most expensive). |

### Optional: Custom Domain

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `custom_domain` | `object` | `null` | Custom domain configuration. When `null` (default), the site is served via the CloudFront `*.cloudfront.net` domain. When provided, all fields are required. |

**`custom_domain` object fields:**

| Field | Type | Description |
|-------|------|-------------|
| `domain_name` | `string` | The custom domain name (e.g. `www.example.com`). A Route53 A-record alias is created pointing to the CloudFront distribution. |
| `hosted_zone_id` | `string` | Route53 hosted zone ID for the domain. |
| `certificate_arn` | `string` | ARN of an ACM certificate covering the domain name. **IMPORTANT: The certificate MUST be in the `us-east-1` region** — this is a CloudFront requirement regardless of where other resources are deployed. The certificate must already exist (BYO). |

### Optional: Tags

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tags` | `map(string)` | `{}` | Map of tags applied to all resources (S3 bucket, CloudFront distribution). |

## Outputs

| Name | Description |
|------|-------------|
| `bucket_name` | Name of the S3 bucket. Use this for `aws s3 sync` commands. |
| `bucket_arn` | ARN of the S3 bucket. |
| `distribution_id` | ID of the CloudFront distribution. Use this for cache invalidation: `aws cloudfront create-invalidation --distribution-id <id> --paths "/*"`. |
| `distribution_domain_name` | CloudFront domain name (`*.cloudfront.net`). |
| `site_url` | Full URL of the site. Returns `https://<custom_domain>` if configured, otherwise `https://<cloudfront_domain>`. |
