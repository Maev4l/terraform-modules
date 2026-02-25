# Edited by CLAUDE

locals {
  create_domain = var.custom_domain != null
}

resource "aws_cloudfront_origin_access_control" "this" {
  name                              = var.site_name
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = var.index_document
  price_class         = var.price_class
  aliases             = local.create_domain ? [var.custom_domain.domain_name] : []
  tags                = var.tags

  origin {
    domain_name              = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id                = aws_s3_bucket.this.id
    origin_access_control_id = aws_cloudfront_origin_access_control.this.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = aws_s3_bucket.this.id
    viewer_protocol_policy = "redirect-to-https"
    cache_policy_id          = var.cache_policy_id
    origin_request_policy_id = var.origin_request_policy_id
    compress                 = true
  }

  dynamic "custom_error_response" {
    for_each = var.spa_mode ? [1] : []

    content {
      error_code            = 403
      response_code         = 200
      response_page_path    = "/${var.index_document}"
      error_caching_min_ttl = 0
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = !local.create_domain
    acm_certificate_arn            = local.create_domain ? var.custom_domain.certificate_arn : null
    ssl_support_method             = local.create_domain ? "sni-only" : null
    minimum_protocol_version       = local.create_domain ? "TLSv1.2_2021" : null
  }
}

resource "aws_route53_record" "this" {
  count = local.create_domain ? 1 : 0

  zone_id = var.custom_domain.hosted_zone_id
  name    = var.custom_domain.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "ipv6" {
  count = local.create_domain ? 1 : 0

  zone_id = var.custom_domain.hosted_zone_id
  name    = var.custom_domain.domain_name
  type    = "AAAA"

  alias {
    name                   = aws_cloudfront_distribution.this.domain_name
    zone_id                = aws_cloudfront_distribution.this.hosted_zone_id
    evaluate_target_health = false
  }
}
