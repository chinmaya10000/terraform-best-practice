resource "aws_db_subnet_group" "bankapp" {
  name       = "bankapp-db-subnet"
  subnet_ids = module.vpc.private_subnets

  tags = local.tags
}

resource "aws_db_instance" "mysql" {
  identifier              = "bankapp-mysql"
  allocated_storage       = 20
  engine                  = "mysql"
  multi_az                = true
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_name                 = "bankappdb"
  username                = "root"
  password                = "MySecurePass123!"
  skip_final_snapshot     = true
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  db_subnet_group_name    = aws_db_subnet_group.bankapp.name
  publicly_accessible     = false
  backup_retention_period = 7

  tags = local.tags

  depends_on = [aws_db_subnet_group.bankapp]
}