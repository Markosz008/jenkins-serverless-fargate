# 1. ECS Cluster - Ez a "logikai keret" a konténereknek
resource "aws_ecs_cluster" "main" {
  name = "serverless-cluster"
}

# 2. Security Group a Load Balancernek (ALB)
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  vpc_id      = aws_vpc.serverless_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 3. Security Group a Fargate konténereknek
resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs-tasks-sg"
  vpc_id      = aws_vpc.serverless_vpc.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id] # Csak az ALB felől jöhet forgalom!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. IAM Role a Fargate-nek, hogy fusson (Execution Role)
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Kell még egy alap policy a logoláshoz és az ECR eléréshez
resource "aws_iam_role_policy_attachment" "ecs_task_execution_basic" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
