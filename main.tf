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
  vpc_cidr_block = "172.16.0.0/16"
  public_subnets = {
    "eks_example_public_1" = {
      cidr_block = "172.16.0.0/20"
    }
    "eks_example_public_2" = {
      cidr_block = "172.16.16.0/20"
    }
  }
  private_subnets = {
    "eks_example_private_1" = {
      cidr_block = "172.16.128.0/20"
    }
    "eks_example_private_2" = {
      cidr_block = "172.16.144.0/20"
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

resource "aws_internet_gateway" "eks_example" {
  vpc_id = aws_vpc.eks_example_vpc.id

  tags = {
    "Name" = "eks_example"
  }
}

resource "aws_eip" "eks_example_nat" {
  vpc = true
}

resource "aws_nat_gateway" "eks_example" {
  allocation_id = aws_eip.eks_example_nat.id
  subnet_id     = sort([for s in aws_subnet.eks_example_public: s.id])[0]

  tags = {
    "Name" = "eks_example"
  }

  depends_on = [
    aws_internet_gateway.eks_example
  ]
}

resource "aws_network_acl" "eks_example_public" {
  vpc_id = aws_vpc.eks_example_vpc.id

  subnet_ids = [for s in aws_subnet.eks_example_public : s.id]

  ingress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    rule_no    = 100
  }

  egress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    rule_no    = 100
  }

  tags = {
    "Name" = "eks_example_public"
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

resource "aws_network_acl" "eks_example_private" {
  vpc_id = aws_vpc.eks_example_vpc.id

  subnet_ids = [for s in aws_subnet.eks_example_private : s.id]

  egress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1"
    from_port  = 0
    to_port    = 0
    rule_no    = 100
  }

  tags = {
    "Name" = "eks_example_private"
  }
}

resource "aws_route_table" "eks_example_private" {
  vpc_id = aws_vpc.eks_example_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.eks_example.id
  }

  tags = {
    "Name" = "eks_example_private"
  }
}

resource "aws_route_table_association" "eks_example_private" {
  for_each       = aws_subnet.eks_example_private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.eks_example_private.id
}

resource "aws_subnet" "eks_example_private" {
  for_each   = local.private_subnets
  vpc_id     = aws_vpc.eks_example_vpc.id
  cidr_block = each.value.cidr_block

  tags = { "Name" = each.key }
}
