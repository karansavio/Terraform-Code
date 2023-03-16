

resource "aws_wafv2_ip_set" "ipset" {
  name               = var.ipset_name
  ip_address_version = var.ip_address_version
  scope              = var.scope
  addresses          = var.ip_addresses

}

resource "aws_wafv2_rule_group" "rule_group" {
  name     = "Owasp-Top-10-Rule-Group"
  scope    = "REGIONAL"
  capacity = 100

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "wafv2-rule-group-metric"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "Rate-Limit-Rule"
    priority = 0

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 100
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "Rate-Limit-Rule-Metric"
      sampled_requests_enabled   = false
    }

  }
}

# Create a set of rules that block appropriate OWASP top 10 attacks

resource "aws_wafv2_web_acl" "owasp_web_acl" {
  name        = "OWASP-Top-10"
  scope       = "REGIONAL"
  description = "Block OWASP Top 10 attacks"

  default_action {
    dynamic "allow" {
      for_each = var.default_action == "allow" ? [1] : []
      content {}
    }

    dynamic "block" {
      for_each = var.default_action == "block" ? [1] : []
      content {}
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "OWASP-Top-10-Metrics"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "Rate-Limit-Rule"
    priority = 0

    override_action {
      none {}
    }

    statement {
      rule_group_reference_statement {
        arn = aws_wafv2_rule_group.rule_group.arn
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "Rate-Limit-Rule-Metric"
      sampled_requests_enabled   = true
    }
  }

  dynamic "rule" {
    for_each = var.managed_rules
    content {
      name     = rule.value.name
      priority = rule.value.priority

      override_action {
        dynamic "none" {
          for_each = rule.value.override_action == "none" ? [1] : []
          content {}
        }

        dynamic "count" {
          for_each = rule.value.override_action == "count" ? [1] : []
          content {}
        }
      }

      statement {
        managed_rule_group_statement {
          name        = rule.value.name
          vendor_name = rule.value.vendor_name

          dynamic "excluded_rule" {
            for_each = rule.value.excluded_rules
            content {
              name = excluded_rule.value
            }
          }
        }
      }

      visibility_config {
        cloudwatch_metrics_enabled = true
        metric_name                = rule.value.name
        sampled_requests_enabled   = true
      }
    }

  }
}
