# VPC Configuration for EKS Cluster
resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr

  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.env}-vpc"
  }
}

# IGW for Public Subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.env}-igw"
  }
}

# Public Subnets Configuration
resource "aws_subnet" "public" {
  count = length(local.public_subnets)

  vpc_id = aws_vpc.main.id
  cidr_block = local.public_subnets[count.index]
  availability_zone = local.azs[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.env}-public-${local.azs[count.index]}"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${local.env}-public-rt"
  }
}

# Associate Public Subnets with Route Table
resource "aws_route_table_association" "public" {
  count = length(local.public_subnets)

  subnet_id = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Subnets Configuration
resource "aws_subnet" "private" {
  for_each = local.private_subnets

  vpc_id = aws_vpc.main.id
  cidr_block = each.value.cidr
  availability_zone = each.value.az

  tags = {
    Name = "${local.env}-private-${each.value.az}"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${local.env}-${local.eks_name}" = "owned"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.env}-nat-eip"
  }
}

# NAT Gateway for Private Subnets
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id = aws_subnet.public[0].id

  tags = {
    Name = "${local.env}-nat-gateway"
  }

  depends_on = [ aws_internet_gateway.igw ]
}

# Route Table for Private Subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${local.env}-private-rt"
  }
}

# Associate Private Subnets with Route Table
resource "aws_route_table_association" "private" {
  for_each = local.private_subnets

  subnet_id = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private.id
}
