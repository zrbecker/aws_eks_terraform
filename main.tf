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
    "Name" : "eks_example_vpc"
  }
}
