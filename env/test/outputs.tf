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

output "ecs_alb_arn" {

  value = aws_lb.nginx_alb.arn
  
}
