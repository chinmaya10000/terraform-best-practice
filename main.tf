provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source         = "./modules/vpc"
  vpc_cidr_block = var.vpc_cidr_block
  env_prefix     = var.env_prefix
}

module "alb" {
  source      = "./modules/alb"
  vpc_id      = module.vpc.vpc_id
  env_prefix  = var.env_prefix
  server_port = var.server_port
  subnet_ids  = module.vpc.public_subnet_ids
}

module "ec2_autoscaling" {
  source           = "./modules/ec2_autoscaling"
  vpc_id           = module.vpc.vpc_id
  server_port      = var.server_port
  env_prefix       = var.env_prefix
  image_id         = var.image_id
  instance_type    = var.instance_type
  subnet_ids       = module.vpc.public_subnet_ids
  target_group_arn = module.alb.target_group_arn
  alb_sg_id        = module.alb.alb_sg_id
}
