terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

locals {
  prefix = "eks_example"
}

module "network" {
  source = "./network"

  prefix                 = local.prefix
  vpc_cidr_block         = "172.16.0.0/16"
  enable_private_subnets = false
}

module "cluster" {
  source = "./eks_cluster"

  prefix     = local.prefix
  subnet_ids = module.network.public_subnet_ids
}
