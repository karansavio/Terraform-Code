output "vpc" {
    value = module.vpc.vpc_id
}

output "private_subnets" {
    value = module.vpc.private_subnets
}

output "public_subnets" {
    value = module.vpc.public_subnets
}

output "ecs_ngix_service_name" {
    value = aws_ecs_service.nginx_service.name
}

output "ecs_nginx_cluster_arn" {
    value = aws_ecs_cluster.nginx_cluster.arn
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
