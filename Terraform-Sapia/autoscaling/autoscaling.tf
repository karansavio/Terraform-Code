
#Define Cloudwatch alarms for CPU and Memory Usage
resource "aws_cloudwatch_metric_alarm" "cpu_alarm" {
  alarm_name          = "${var.service_name}-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  dimensions = {
    ClusterName          = var.cluster_name
    ServiceName          = var.service_name
    TaskDefinitionFamily = var.task_definition_family
  }
}

#Define Cloudwatch Memeory Alarm
resource "aws_cloudwatch_metric_alarm" "memory_alarm" {
  alarm_name          = "${var.service_name}-memory-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = "60"
  statistic           = "Average"
  threshold           = "80"
  dimensions = {
    ClusterName          = var.cluster_name
    ServiceName          = var.service_name
    TaskDefinitionFamily = var.task_definition_family
  }
}

#Define autoscaling policies for CPU and Memory Usage
resource "aws_appautoscaling_target" "cpu_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_scheduled_action" "cpu_schedule" {
  name               = "${var.service_name}-cpu-schedule"
  service_namespace  = aws_appautoscaling_target.cpu_target.service_namespace
  resource_id        = aws_appautoscaling_target.cpu_target.resource_id
  scalable_dimension = aws_appautoscaling_target.cpu_target.scalable_dimension
  schedule           = "cron(0 7 * * ? *)"

  scalable_target_action {
    min_capacity = 2
    max_capacity = 10
  }
}
resource "aws_appautoscaling_scheduled_action" "cpu_scale_out" {
  name               = "${var.service_name}-scheduled-action"
  service_namespace  = aws_appautoscaling_target.cpu_target.service_namespace
  resource_id        = aws_appautoscaling_target.cpu_target.resource_id
  scalable_dimension = aws_appautoscaling_target.cpu_target.scalable_dimension
  schedule           = "cron(0 19 * * ? *)"

  scalable_target_action {
    min_capacity = 1
    max_capacity = 1
  }

  depends_on = [aws_appautoscaling_target.cpu_target]

}


resource "aws_appautoscaling_policy" "cpu_policy" {
  name               = "${var.service_name}-cpu-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.cpu_target.resource_id
  scalable_dimension = aws_appautoscaling_target.cpu_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.cpu_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = "50"
  }
}

resource "aws_appautoscaling_target" "memory_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${var.cluster_name}/${var.service_name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "memory_policy" {
  name               = "${var.service_name}-memory-policy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.memory_target.resource_id
  scalable_dimension = aws_appautoscaling_target.memory_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.memory_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value = "50"
  }
}
