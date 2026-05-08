# 1. Alcsoport az adatbázisnak (hogy tudja, melyik hálózatban lakik)
resource "aws_db_subnet_group" "aurora_subnet_group" {
  name       = "aurora-subnet-group"
  subnet_ids = [aws_subnet.pub_1.id, aws_subnet.pub_2.id]
}

# 2. Security Group az Aurorának
resource "aws_security_group" "aurora_sg" {
  name   = "aurora-sg"
  vpc_id = aws_vpc.serverless_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_tasks_sg.id] # Csak a Fargate felől jöhet kérés!
  }
}

# 3. Az Aurora Serverless v2 Cluster
resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier      = "serverless-aurora-cluster"
  engine                  = "aurora-mysql"
  engine_mode             = "provisioned" # v2-höz ez kell
  engine_version          = "8.0.mysql_aurora.3.05.2"
  database_name           = "flaskdb"
  master_username         = "admin"
  master_password         = var.db_password # Később használhatunk Secrets Manager-t
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_db_subnet_group.aurora_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.aurora_sg.id]

  scaling_configuration {
    max_capacity = 1
    min_capacity = 1
  }
}

# 4. Az adatbázis példány (Instance)
resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier = aws_rds_cluster.aurora_cluster.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_cluster.engine
  engine_version     = aws_rds_cluster.aurora_cluster.engine_version
}

# --- OUTPUTS ---
output "aurora_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
}
