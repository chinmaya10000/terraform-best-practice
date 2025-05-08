provider "aws" {
  region = var.aws_region
}

# VPC for Cluster
data "aws_availability_zones" "azs" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = var.name
  cidr = var.vpc_cidr_block

  azs = data.aws_availability_zones.azs.names
  private_subnets = var.private_subnets_cidr_blocks
  public_subnets  = var.public_sunets_cidr_blocks

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.tags
}

# EKS Cluster
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name = var.name
  cluster_version = var.k8s_version
  cluster_endpoint_public_access = true

  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_addons = {
    kube-proxy = {}
    vpc-cni = {}
    coredns = {}
  }

  eks_managed_node_groups = {
    initial = {
        instance_type = ["t2.medium"]
        min_size = 2
        max_size = 4
        desired_size = 2
    }
  }

  tags = var.tags
}

module "eks-blueprints-addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.0"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_metrics_server = true
#   cluster_autoscaler = {
#     set = [
#       {
#         name = "extraArgs.scale-down-unneeded-time"
#         value = "1m"
#       },
#       {
#         name = "extraArgs.skip-nodes-with-local-storage"
#         value = false
#       },
#       {
#         name = "extraArgs.skip-nodes-with-system-pods"
#         value = false
#       }
#     ]
#   }
}