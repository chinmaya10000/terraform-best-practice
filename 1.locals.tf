locals {
  aws_region = "us-east-2"
  vpc_cidr   = "10.0.0.0/16"
  env        = "dev"
  eks_name   = "myapp-eks"

  azs            = ["us-east-2a", "us-east-2b", "us-east-2c"]
  public_subnets = ["10.0.0.0/19", "10.0.32.0/19"]

  private_subnets = {
    public_1 = {
      cidr = cidrsubnet(local.vpc_cidr, 3, 2)
      az   = local.azs[0]
    }
    public_2 = {
      cidr = cidrsubnet(local.vpc_cidr, 3, 3)
      az   = local.azs[1]
    }
  }
}