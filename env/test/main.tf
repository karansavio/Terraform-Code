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

module "waf_rules" {
  source = "../../modules/waf"
}

resource "aws_wafv2_web_acl_association" "owasp_web_assoc" {
  resource_arn = aws_lb.nginx_alb.arn
  web_acl_arn  = module.waf_rules.owasp_web_acl_arn
}

#Included the autoscaling module to monitor the ECS service
module "autoscaling" {
  source                 = "../../modules/autoscaling"
  service_name           = aws_ecs_service.nginx_service.name
  cluster_name           = aws_ecs_cluster.nginx_cluster.id
  task_definition_family = aws_ecs_task_definition.nginx_task.family
}
