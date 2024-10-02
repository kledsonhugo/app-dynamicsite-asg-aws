resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "sn-pub-az1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = var.subnet_pub_az1a_cidr
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sn-pub-az1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1c"
  cidr_block              = var.subnet_pub_az1c_cidr
  map_public_ip_on_launch = true
}

resource "aws_subnet" "sn-priv-az1a" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1a"
  cidr_block              = var.subnet_priv_az1a_cidr
}

resource "aws_subnet" "sn-priv-az1c" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = "us-east-1c"
  cidr_block              = var.subnet_priv_az1c_cidr
}

resource "aws_eip" "eip-az1a" {}

resource "aws_nat_gateway" "ngw-az1a" {
    allocation_id = aws_eip.eip-az1a.id
    subnet_id     = aws_subnet.sn-pub-az1a.id
}

resource "aws_eip" "eip-az1c" {}

resource "aws_nat_gateway" "ngw-az1c" {
    allocation_id = aws_eip.eip-az1c.id
    subnet_id     = aws_subnet.sn-pub-az1c.id
}

resource "aws_route_table" "rt-pub" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "rt-priv-az1a" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw-az1a.id
  }
}

resource "aws_route_table" "rt-priv-az1c" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw-az1c.id
  }
}

resource "aws_route_table_association" "sn-pub-az1a" {
  subnet_id      = aws_subnet.sn-pub-az1a.id
  route_table_id = aws_route_table.rt-pub.id
}

resource "aws_route_table_association" "sn-pub-az1c" {
  subnet_id      = aws_subnet.sn-pub-az1c.id
  route_table_id = aws_route_table.rt-pub.id
}

resource "aws_route_table_association" "sn-priv-az1a" {
  subnet_id      = aws_subnet.sn-priv-az1a.id
  route_table_id = aws_route_table.rt-priv-az1a.id
}

resource "aws_route_table_association" "sn-priv-az1c" {
  subnet_id      = aws_subnet.sn-priv-az1c.id
  route_table_id = aws_route_table.rt-priv-az1c.id
}
