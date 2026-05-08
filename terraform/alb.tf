# 1. Az Load Balancer maga
resource "aws_lb" "main" {
  name               = "serverless-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]

  tags = { Name = "Serverless-ALB" }
}

# 2. Target Group - Itt fontos a target_type = "ip"!
# Fargate-nél nem példányokat, hanem IP címeket kap az ALB.
resource "aws_lb_target_group" "app_tg" {
  name        = "app-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.serverless_vpc.id
  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# 3. Listener - Ami a 80-as portot figyeli
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# Output: Hogy a végén tudjuk, mit kell beírni a böngészőbe
output "alb_dns_name" {
  value = aws_lb.main.dns_name
}
