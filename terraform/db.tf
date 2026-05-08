# 1. Alcsoport az adatbázisnak
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-group"
  subnet_ids = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
}

# 2. Security Group
resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = aws_vpc.serverless_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }
}

# 3. Sima RDS MySQL Instance (Free Tier barát)
resource "aws_db_instance" "mysql_db" {
  allocated_storage    = 20
  db_name              = "flaskdb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro" # Ez a Free Tier!
  username             = "admin"
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids = [aws_security_group.db_sg.id]
}

# Output módosítása
output "db_endpoint" {
  value = aws_db_instance.mysql_db.endpoint
}
