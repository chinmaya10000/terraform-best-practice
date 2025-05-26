resource "aws_subnet" "public_zone1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/19"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name                                    = "dev-public-subnet-zone1"
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/dev-eks-cluster" = "owned"
  }
}

resource "aws_subnet" "public_zone2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.32.0/19"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = true

  tags = {
    Name                                    = "dev-public-subnet-zone2"
    "kubernetes.io/role/elb"                = "1"
    "kubernetes.io/cluster/dev-eks-cluster" = "owned"
  }
}