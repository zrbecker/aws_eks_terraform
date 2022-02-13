
locals {
  public_cidr_block  = cidrsubnet(var.vpc_cidr_block, 1, 0)
  private_cidr_block = cidrsubnet(var.vpc_cidr_block, 1, 1)
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true

  tags = {
    "Name" = format("%s_vpc", var.prefix)
  }
}

resource "aws_default_network_acl" "default" {
  default_network_acl_id = aws_vpc.vpc.default_network_acl_id

  tags = {
    "Name" = format("%s_default", var.prefix)
  }
}

resource "aws_default_route_table" "default" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id

  tags = {
    "Name" = format("%s_default", var.prefix)
  }
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = format("%s_default", var.prefix)
  }
}

resource "aws_subnet" "public" {
  count = length(data.aws_availability_zones.available.names)

  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  cidr_block = cidrsubnet(
    local.public_cidr_block,
    ceil(log(length(data.aws_availability_zones.available.names), 2)),
    count.index
  )

  tags = {
    "Name" = format("%s_public_%d", var.prefix, count.index)
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = format("%s_igw", var.prefix)
  }
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.public.*.id

  ingress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1"
    icmp_code  = 0
    icmp_type  = 0
    from_port  = 0
    to_port    = 0
    rule_no    = 100
  }

  egress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1"
    icmp_code  = 0
    icmp_type  = 0
    from_port  = 0
    to_port    = 0
    rule_no    = 100
  }

  tags = {
    "Name" = format("%s_public", var.prefix)
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    "Name" = format("%s_public", var.prefix)
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_subnet" "private" {
  count = var.enable_private_subnets ? length(data.aws_availability_zones.available.names) : 0

  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[count.index]

  cidr_block = cidrsubnet(
    local.private_cidr_block,
    ceil(log(length(data.aws_availability_zones.available.names), 2)),
    count.index
  )

  tags = {
    "Name" = format("%s_private_%d", var.prefix, count.index)
  }
}

resource "aws_eip" "nat" {
  count = length(aws_subnet.private) > 0 ? 1 : 0

  vpc = true

  tags = {
    "Name" = format("%s_nat_%d", var.prefix, count.index)
  }
}

resource "aws_nat_gateway" "nat" {
  count = length(aws_eip.nat)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    "Name" = format("%s_nat_%d", var.prefix, count.index)
  }

  depends_on = [
    aws_internet_gateway.igw
  ]
}

resource "aws_network_acl" "private" {
  count = length(aws_subnet.private) > 0 ? 1 : 0

  vpc_id     = aws_vpc.vpc.id
  subnet_ids = aws_subnet.private.*.id

  ingress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "tcp"
    icmp_code  = 0
    icmp_type  = 0
    from_port  = 32768
    to_port    = 60999
    rule_no    = 100
  }

  egress {
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    protocol   = "-1"
    icmp_code  = 0
    icmp_type  = 0
    from_port  = 0
    to_port    = 0
    rule_no    = 100
  }

  tags = {
    "Name" = format("%s_private", var.prefix)
  }
}

resource "aws_route_table" "private" {
  count = length(aws_nat_gateway.nat)

  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[count.index].id
  }

  tags = {
    "Name" = format("%s_private_%d", var.prefix, count.index)
  }
}

resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[0].id
}
