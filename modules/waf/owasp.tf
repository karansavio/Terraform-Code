

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
    allow {}
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

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
        rule_action_override {
          action_to_use {
            count {}
          }

          name = "SizeRestrictions_QUERYSTRING"
        }

        rule_action_override {
          action_to_use {
            count {}
          }

          name = "NoUserAgent_HEADER"
        }

      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }

  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "OWASP-Top-10"
    sampled_requests_enabled   = true
  }

}

# module "ecs_lb" {
#     source = "../../env/test"

#     var1 = ecs_lb.ecs_alb_arn
# }

# resource "aws_wafv2_web_acl_association" "owasp_web_assoc" {
# #   resource_arn = aws_lb.nginx_alb.arn
#   resource_arn = module.ecs_lb.ecs_alb_arn
#   web_acl_arn  = aws_wafv2_web_acl.owasp_web_acl.arn
# }