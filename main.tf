terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 3.63"  # lock "3.63"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = "~> 1.0"
}

#############
# S3 Backend
#############

terraform {
  backend "s3" {
    bucket = "arbisofts-terraform"
    key    = "arbisoft-dev.tfstate"
    region = "us-east-1"

  }
}

#######
# Vpc
#######

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.EKS_CLUSTER_NAME
  cidr = "10.11.0.0/16"

  azs              = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets  = ["10.11.16.0/20", "10.11.32.0/20", "10.11.48.0/20"]
  public_subnets   = ["10.11.64.0/20", "10.11.80.0/20", "10.11.96.0/20"]
  database_subnets = ["10.11.1.0/24", "10.11.2.0/24", "10.11.3.0/24"]

  map_public_ip_on_launch = true
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = false
  create_database_nat_gateway_route      = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.EKS_CLUSTER_NAME}" = "owned"
    "kubernetes.io/role/elb"                        = "1"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.EKS_CLUSTER_NAME}" = "owned"
    "kubernetes.io/role/elb"                        = "1"
  }

}


########################
# EKS Cluster Deployment
########################
resource "null_resource" "eks" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "bash eksctl.sh"
  }
}

############################
# EKS ALB Ingress Deployment
############################
resource "null_resource" "eks-alb-ingress-controller" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "bash alb-ingress.sh"
  }
  depends_on = [null_resource.eks]
}

################################
# EKS EBS/SecretStore CSI Driver
################################
resource "null_resource" "ebscsi-secretcsi-controllers" {
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = "bash csi-drivers.sh"
  }
  depends_on = [null_resource.eks]
}
