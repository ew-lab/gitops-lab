############################################################
# Provider
############################################################
provider "aws" {
  region = var.region
}

############################################################
# Networking – minimal three-AZ VPC (for brevity, public subnets only)
############################################################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"

  name = "${var.cluster_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnets  = ["10.0.0.0/20", "10.0.16.0/20", "10.0.32.0/20"]

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project = var.cluster_name
  }
}

############################################################
# EKS cluster
############################################################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.13.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.30"

  subnet_ids = module.vpc.public_subnets
  vpc_id     = module.vpc.vpc_id

  enable_irsa = true   # needed by Flux controllers

  managed_node_groups = {
    default = {
      instance_types = [var.node_instance_type]
      desired_size   = 1
      min_size       = 1
      max_size       = 1

      tags = {
        Name = "${var.cluster_name}-node"
      }
    }
  }

  tags = {
    Project = var.cluster_name
  }
}

############################################################
# IRSA IAM role for Flux & other controllers (example)
############################################################
module "flux_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.40.0"

  role_name           = "${var.cluster_name}-flux"
  attach_external_secrets_policy = false # flip on if you demo ESO
  oidc_providers      = {
    main = {
      provider  = module.eks.oidc_provider
      namespace = "flux-system"
      service_accounts = ["*"]
    }
  }
}
