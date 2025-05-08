locals {
  aws_region                 = "us-east-2"
  vpc_cidr_block             = "10.0.0.0/16"
  name                       = "myapp-ecs"
  private_subnet_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets_cidr_blocks = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  tags = {
    Environment = "dev"
    Project     = "bankapp"
  }
}