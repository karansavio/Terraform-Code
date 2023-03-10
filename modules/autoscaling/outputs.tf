output "cloudwatch_metric_alarm_name_cpu" {
  value = aws_cloudwatch_metric_alarm.cpu_alarm
}

output "cloudwatch_metric_alarm_name_memory" {
  value = aws_cloudwatch_metric_alarm.memory_alarm
}

output "cloudwatch_metric_alarm_arn_cpu" {
  value = aws_cloudwatch_metric_alarm.cpu_alarm.arn
}

output "cloudwatch_metric_alarm_arn_memory" {
  value = aws_cloudwatch_metric_alarm.memory_alarm.arn
}

output "cloudwatch_metric_alarm_comparison_operator_cpu" {
  value = aws_cloudwatch_metric_alarm.cpu_alarm.comparison_operator
}

output "cloudwatch_metric_alarm_comparison_operator_memory" {
  value = aws_cloudwatch_metric_alarm.memory_alarm.comparison_operator
}

output "cloudwatch_metric_alarm_evaluation_periods_cpu" {
  value = aws_cloudwatch_metric_alarm.cpu_alarm.evaluation_periods
}

output "cloudwatch_metric_alarm_evaluation_periods_memory" {
  value = aws_cloudwatch_metric_alarm.memory_alarm.evaluation_periods
}