module "network" {
  source = "./modules/network"
  subnet_bits = var.subnet_bits
  public_subnet_count = var.public_subnet_count
  private_subnet_count = var.private_subnet_count
  availability_zones = var.availability_zones
}

resource "aws_db_subnet_group" "main" {
  name = "demo-aurora-subnet-group"
  subnet_ids = [for subnet in module.network.aws_private_subnet : subnet.id]
}

resource "aws_rds_cluster" "main" {
  cluster_identifier = "bjgomes-demo"
  engine             = "aurora-mysql"
  engine_mode        = "provisioned"
  engine_version     = "8.0"
  database_name      = "wordpress"
  master_username    = "admin"
  master_password    = "password1234"
  db_subnet_group_name = aws_db_subnet_group.main.name
  vpc_security_group_ids = [module.network.aws_security_group_id]
  skip_final_snapshot = true

  serverlessv2_scaling_configuration {
    max_capacity = 2.0
    min_capacity = 0.5
  }
}

resource "aws_rds_cluster_instance" "main" {
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
}