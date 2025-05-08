output "rds_endpoint" {
  value       = aws_db_instance.mysql.address
  description = "The endpoint of the RDS instance."
}