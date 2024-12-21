# Create CloudFront Distribution with custom domain name
locals {
  s3_ssl_origin_id = "myS3StaticWebsiteSSLOrigin"
}

resource "aws_cloudfront_distribution" "s3_static_website_ssl" {
  origin {

    domain_name = aws_s3_bucket_website_configuration.this.website_endpoint
    origin_id   = local.s3_ssl_origin_id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1"]
    }
  }

  enabled             = true
  is_ipv6_enabled     = false
  comment             = "This is my super fun distribution"
  default_root_object = "index.html"

  aliases = ["cloudresume.cld1.mrcloudmustache.com"]


  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_ssl_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.this.arn
    ssl_support_method             = "sni-only"
  }
}

# Request public cert
data "aws_route53_zone" "this" {
  name         = "cld1.mrcloudmustache.com"
  private_zone = false
}

resource "aws_acm_certificate" "this" {
  domain_name       = "cloudresume.cld1.mrcloudmustache.com"
  validation_method = "DNS"

  tags = {
    Environment = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "this" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.this : record.fqdn]
}

# Create R53 A alias record towards the distribution
resource "aws_route53_record" "cloudresume_alias" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = aws_acm_certificate.this.domain_name
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_static_website_ssl.domain_name
    zone_id                = aws_cloudfront_distribution.s3_static_website_ssl.hosted_zone_id
    evaluate_target_health = true
  }
}