output "owasp_web_acl_arn" {
    value = aws_wafv2_web_acl.owasp_web_acl.arn
  
}

output "ipset_id" {
  value = aws_wafv2_ip_set.ipset.id
}

output "rate_limit_rule_group_id" {
  value = aws_wafv2_rule_group.rule_group.id
}

output "rate_limit_rule_group_arn" {
  value = aws_wafv2_rule_group.rule_group.arn
}