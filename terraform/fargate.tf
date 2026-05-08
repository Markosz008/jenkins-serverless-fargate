# 1. CloudWatch Log Group - Hogy lásd a konténerek kimenetét (docker logs helyett)
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/flask-app"
  retention_in_days = 7
}

# 2. Task Definition - Itt írjuk le a konténereket
resource "aws_ecs_task_definition" "app" {
  family                   = "flask-app-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"   # 0.5 vCPU
  memory                   = "1024"  # 1 GB RAM
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "flask-app"
      image     = "markosz008/flask-app:latest" # A Jenkins ide fog pusholni
      essential = true
      portMappings = [{
        containerPort = 80
        hostPort      = 80
      }]
      environment = [
        { name = "DB_HOST", value = aws_rds_cluster.aurora_cluster.endpoint },
        { name = "DB_USER", value = "admin" },
        { name = "DB_PASS", value = var.db_password },
        { name = "DB_NAME", value = "flaskdb" },
        { name = "REDIS_HOST", value = "localhost" } # Mivel egy Taskban vannak, látják egymást localhoston
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/flask-app"
          "awslogs-region"        = "eu-central-1"
          "awslogs-stream-prefix" = "flask"
        }
      }
    },
    {
      name      = "redis"
      image     = "redis:alpine"
      essential = true
      portMappings = [{
        containerPort = 6379
        hostPort      = 6379
      }]
    }
  ])
}

# 3. ECS Service - Ez tartja életben a konténereket
resource "aws_ecs_service" "main" {
  name            = "flask-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_tasks_sg.id]
    subnets          = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "flask-app"
    container_port   = 80
  }
}
