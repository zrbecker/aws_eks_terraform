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
  vpc_cidr_block = "10.0.0.0/16"
  public_subnets = {
    "eks_example_public_1" = {
      cidr_block = "10.0.8.0/24"
    }
    "eks_example_public_2" = {
      cidr_block = "10.0.9.0/24"
    }
  }
  private_subnets = {
    "eks_example_private_1" = {
      cidr_block = "10.0.16.0/24"
    }
    "eks_example_private_2" = {
      cidr_block = "10.0.17.0/24"
    }
  }
}

resource "aws_vpc" "eks_example_vpc" {
  cidr_block = local.vpc_cidr_block
  tags = {
    "Name" = "eks_example"
  }
}

resource "aws_default_network_acl" "eks_example_default" {
  default_network_acl_id = aws_vpc.eks_example_vpc.default_network_acl_id

  subnet_ids = concat(
    [for s in aws_subnet.eks_example_private : s.id],
    [for s in aws_subnet.eks_example_public : s.id]
  )

  # no rules defined, deny all traffic in this ACL
  tags = {
    "Name" = "eks_example"
  }
}

resource "aws_default_route_table" "eks_example_default" {
  default_route_table_id = aws_vpc.eks_example_vpc.default_route_table_id

  route = []

  tags = {
    "Name" = "eks_example"
  }
}

resource "aws_subnet" "eks_example_public" {
  for_each   = local.public_subnets
  vpc_id     = aws_vpc.eks_example_vpc.id
  cidr_block = each.value.cidr_block

  tags = { "Name" = each.key }
}

resource "aws_subnet" "eks_example_private" {
  for_each   = local.private_subnets
  vpc_id     = aws_vpc.eks_example_vpc.id
  cidr_block = each.value.cidr_block

  tags = { "Name" = each.key }
}
