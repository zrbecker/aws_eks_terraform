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

resource "aws_vpc" "eks_example_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    "Name" = "eks_example"
  }
}

resource "aws_default_network_acl" "eks_example_default" {
  default_network_acl_id = aws_vpc.eks_example_vpc.default_network_acl_id

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
