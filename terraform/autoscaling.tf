# terraform/autoscaling.tf

# 1. Megmondjuk, hogy mit skálázzon (a mi Fargate service-ünket)
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 3 # Maximum 3 konténer futhat egyszerre
  min_capacity       = 1 # Minimum 1 konténernek mindig futnia kell
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# 2. Skálázási szabály (Target Tracking: CPU 70%-on tartása)
resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 70.0
    scale_in_cooldown  = 300 # Mennyit várjon (mp), mielőtt visszaskáláz
    scale_out_cooldown = 60  # Mennyit várjon (mp), mielőtt újabb konténert indít
  }
}