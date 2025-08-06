# WAF Web ACL
resource "aws_wafv2_web_acl" "main" {
  name  = "${var.project_name}-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  # Rule 1: AWS Managed Core Rule Set
  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        # Exclude specific rules if needed
        excluded_rule {
          name = "SizeRestrictions_BODY"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "CommonRuleSetMetric"
      sampled_requests_enabled    = true
    }
  }

  # Rule 2: AWS Managed Known Bad Inputs Rule Set
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "KnownBadInputsRuleSetMetric"
      sampled_requests_enabled    = true
    }
  }

  # Rule 3: AWS Managed SQL Injection Rule Set
  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "SQLiRuleSetMetric"
      sampled_requests_enabled    = true
    }
  }

  # Rule 4: Rate Limiting Rule
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 2000
        aggregate_key_type = "IP"

        scope_down_statement {
          geo_match_statement {
            country_codes = ["US", "CA", "GB", "DE", "FR", "JP", "AU"]
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "RateLimitRule"
      sampled_requests_enabled    = true
    }
  }

  # Rule 5: Custom XSS Protection
  rule {
    name     = "CustomXSSProtection"
    priority = 5

    action {
      block {}
    }

    statement {
      or_statement {
        statement {
          xss_match_statement {
            field_to_match {
              query_string {}
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
        statement {
          xss_match_statement {
            field_to_match {
              body {}
            }
            text_transformation {
              priority = 1
              type     = "URL_DECODE"
            }
            text_transformation {
              priority = 2
              type     = "HTML_ENTITY_DECODE"
            }
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "CustomXSSProtection"
      sampled_requests_enabled    = true
    }
  }

  # Rule 6: Block Specific User Agents
  rule {
    name     = "BlockBadUserAgents"
    priority = 6

    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string = "badbot"
        field_to_match {
          single_header {
            name = "user-agent"
          }
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
        positional_constraint = "CONTAINS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "BlockBadUserAgents"
      sampled_requests_enabled    = true
    }
  }

  # Rule 7: Geo-blocking (example: block specific countries)
  rule {
    name     = "GeoBlocking"
    priority = 7

    action {
      block {}
    }

    statement {
      geo_match_statement {
        country_codes = ["CN", "RU", "KP"]  # Example countries to block
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "GeoBlocking"
      sampled_requests_enabled    = true
    }
  }

  # Rule 8: IP Reputation List
  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 8

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "IpReputationListMetric"
      sampled_requests_enabled    = true
    }
  }

  tags = local.common_tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "${var.project_name}WebAcl"
    sampled_requests_enabled    = true
  }
}

# Associate WAF with ALB
resource "aws_wafv2_web_acl_association" "main" {
  resource_arn = aws_lb.main.arn
  web_acl_arn  = aws_wafv2_web_acl.main.arn
}

# CloudWatch Log Group for WAF
resource "aws_cloudwatch_log_group" "waf" {
  name              = "/aws/wafv2/${var.project_name}"
  retention_in_days = 7

  tags = local.common_tags
}

# WAF Logging Configuration
resource "aws_wafv2_web_acl_logging_configuration" "main" {
  resource_arn            = aws_wafv2_web_acl.main.arn
  log_destination_configs = [aws_cloudwatch_log_group.waf.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  redacted_fields {
    single_header {
      name = "cookie"
    }
  }
}

# IP Set for allowed IPs (example)
resource "aws_wafv2_ip_set" "allowed_ips" {
  name               = "${var.project_name}-allowed-ips"
  description        = "Allowed IP addresses"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [
    "192.0.2.0/24",    # Example IP range
    "203.0.113.0/24"   # Example IP range
  ]

  tags = local.common_tags
}

# IP Set for blocked IPs
resource "aws_wafv2_ip_set" "blocked_ips" {
  name               = "${var.project_name}-blocked-ips"
  description        = "Blocked IP addresses"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"

  addresses = [
    "198.51.100.0/24"  # Example blocked IP range
  ]

  tags = local.common_tags
}

# Custom Rule Group (optional)
resource "aws_wafv2_rule_group" "custom" {
  name     = "${var.project_name}-custom-rules"
  scope    = "REGIONAL"
  capacity = 100

  rule {
    name     = "BlockSpecificPath"
    priority = 1

    action {
      block {}
    }

    statement {
      byte_match_statement {
        search_string = "/admin"
        field_to_match {
          uri_path {}
        }
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
        positional_constraint = "STARTS_WITH"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                 = "BlockSpecificPath"
      sampled_requests_enabled    = true
    }
  }

  tags = local.common_tags

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                 = "${var.project_name}CustomRuleGroup"
    sampled_requests_enabled    = true
  }
}
