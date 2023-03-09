provider "aws" {
  region = var.region
}

# #Creating an S3 bucket for multi-region deployment
# terraform {
#   backend "s3" {
#   }
# }

# Create VPC and subnets
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "nginx-vpc"
  cidr = var.cidr_block

  azs             = var.availability_zones
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway = true
  single_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# Create a SG for the nginx server

resource "aws_security_group" "nginx_sg" {
  name_prefix = "NGINX-SG"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = var.http_port
    to_port     = var.http_port
    protocol    = "TCP"
    cidr_blocks = var.application_cidr_blocks
  }

  ingress {
    from_port   = var.https_port
    to_port     = var.https_port
    protocol    = "TCP"
    cidr_blocks = var.application_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.application_cidr_blocks
  }
}

# Create an Application Load Balancer
resource "aws_lb" "nginx_alb" {
  name               = "NGINX-ALB"
  internal           = false
  load_balancer_type = "application"
  subnets            = module.vpc.public_subnets
  security_groups    = [aws_security_group.nginx_sg.id]
}

# Define the ALB listener
resource "aws_lb_listener" "nginx_listener" {
  load_balancer_arn = aws_lb.nginx_alb.arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_lb_target_group.arn
  }
}

resource "aws_lb_target_group" "nginx_lb_target_group" {
  name        = "nginx-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
  }
}


# Create an AWS ECS task definition for the nginx server
resource "aws_ecs_task_definition" "nginx_task" {
  family = "nginx"
  container_definitions = jsonencode([{
    name  = "nginx"
    image = "nginx:latest"
    portMappings = [{
      containerPort = 80
    }]
  }])

  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
}

resource "aws_ecs_cluster" "nginx_cluster" {
  name = "fargate-nginx-cluster"

  tags = {
    Name = "fargate-nginx-cluster"
  }
}

resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.nginx_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = 1

  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 1
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 1
  }

  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.nginx_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_lb_target_group.id
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.nginx_listener
  ]
}

#Create Load Balancer Listener Rule
resource "aws_lb_listener_rule" "listener_rule" {
  listener_arn = aws_lb_listener.nginx_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_lb_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/nginx/*"]
    }
  }
}

resource "aws_wafv2_ip_set" "ipset" {
  name               = "tfIPSet"
  ip_address_version = "IPV4"
  scope              = "REGIONAL"
  addresses          = ["192.0.7.0/24"]

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

resource "aws_wafv2_web_acl_association" "owasp_web_assoc" {
  resource_arn = aws_lb.nginx_alb.arn
  web_acl_arn  = aws_wafv2_web_acl.owasp_web_acl.arn
}

#Included the autoscaling module to monitor the ECS service
module "autoscaling" {
  source                 = "./autoscaling"
  service_name           = aws_ecs_service.nginx_service.name
  cluster_name           = aws_ecs_cluster.nginx_cluster.id
  task_definition_family = aws_ecs_task_definition.nginx_task.family
}
