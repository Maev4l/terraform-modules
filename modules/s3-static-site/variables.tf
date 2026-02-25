# Edited by CLAUDE

# --- Required ---

variable "site_name" {
  description = "Name for the static site (used for S3 bucket and CloudFront naming)"
  type        = string
}

# --- Optional: Content ---

variable "index_document" {
  description = "The default index document served at the root path"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "The error document served for 4xx errors (non-SPA mode)"
  type        = string
  default     = "error.html"
}

variable "spa_mode" {
  description = "Enable SPA routing. When true, 403 errors return the index document with status 200 for client-side routing."
  type        = bool
  default     = true
}

# --- Optional: CloudFront ---

variable "cache_policy_id" {
  description = "CloudFront cache policy ID. Defaults to the AWS managed CachingOptimized policy."
  type        = string
  default     = "658327ea-f89d-4fab-a63d-7e88639e58f6"
}

variable "origin_request_policy_id" {
  description = "CloudFront origin request policy ID. Defaults to the AWS managed CORS-S3Origin policy."
  type        = string
  default     = "88a5eaf4-2f7a-4b3b-b694-47856e546348"
}

variable "price_class" {
  description = "CloudFront distribution price class. Determines which edge locations are used."
  type        = string
  default     = "PriceClass_100"
}

# --- Optional: Custom Domain ---

variable "custom_domain" {
  description = "Custom domain configuration. Set to null (default) to skip domain setup. ACM certificate must be in us-east-1."
  type = object({
    domain_name     = string
    hosted_zone_id  = string
    certificate_arn = string
  })
  default = null
}

# --- Optional: Tags ---

variable "tags" {
  description = "Map of tags to apply to all resources"
  type        = map(string)
  default     = {}
}
