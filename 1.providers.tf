terraform {
  # required_version = ">= 1.0"
  # backend "s3" {
  #   bucket = "chinmaya-terraform-state"
  #   key = "infra/terraform.tfstate"
  #   region = "us-east-2"
  #   dynamodb_table = "chinmaya-terraform-locks"
  #   encrypt = true
  # }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
  }
}

provider "kubernetes" {
  host = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command = "aws"
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}




# terraform workspace show
# Create a new workspace
# terraform workspace new <name of workspace>
# terraform workspace list --> list all workspaces
# terraform workspace select <name of workspace> --> select a workspace