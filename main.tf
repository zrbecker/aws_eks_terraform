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
  vpc_cidr_block = "10.48.0.0/16"
  public_subnets = {
    "eks_example_public_1" = {
      cidr_block = "10.48.16.0/20"
    }
    "eks_example_public_2" = {
      cidr_block = "10.48.32.0/20"
    }
  }
  private_subnets = {
    "eks_example_private_1" = {
      cidr_block = "10.48.48.0/20"
    }
    "eks_example_private_2" = {
      cidr_block = "10.48.64.0/20"
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

  subnet_ids = [for s in aws_subnet.eks_example_private : s.id]

  # no rules defined, deny all traffic in this ACL
  tags = {
    "Name" = "eks_example_default"
  }
}

resource "aws_default_route_table" "eks_example_default" {
  default_route_table_id = aws_vpc.eks_example_vpc.default_route_table_id

  route = []

  tags = {
    "Name" = "eks_example_default"
  }
}

resource "aws_network_acl" "eks_example_public" {
  vpc_id = aws_vpc.eks_example_vpc.id

  subnet_ids = [for s in aws_subnet.eks_example_public : s.id]

  ingress {
    action = "allow"
    cidr_block = "0.0.0.0/0"
    protocol = "-1"
    from_port = 0
    to_port = 0
    rule_no = 100
  }

  egress {
    action = "allow"
    cidr_block = "0.0.0.0/0"
    protocol = "-1"
    from_port = 0
    to_port = 0
    rule_no = 100
  }

  tags = {
    "Name" = "eks_example_public"
  }
}

resource "aws_internet_gateway" "eks_example" {
  vpc_id = aws_vpc.eks_example_vpc.id

  tags = {
    "Name" = "eks_example"
  }
}

resource "aws_route_table" "eks_example_public" {
  vpc_id = aws_vpc.eks_example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_example.id
  }

  tags = {
    "Name" = "eks_example_public"
  }
}

resource "aws_route_table_association" "eks_example_public" {
  for_each       = aws_subnet.eks_example_public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.eks_example_public.id
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
