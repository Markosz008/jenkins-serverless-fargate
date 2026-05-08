resource "aws_vpc" "serverless_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = { Name = "Serverless-VPC" }
}

resource "aws_subnet" "pub_1" {
  vpc_id            = aws_vpc.serverless_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-central-1a"
  map_public_ip_on_launch = true

  tags = { Name = "Serverless-Pub-1" }
}

resource "aws_subnet" "pub_2" {
  vpc_id            = aws_vpc.serverless_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "eu-central-1b"
  map_public_ip_on_launch = true

  tags = { Name = "Serverless-Pub-2" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.serverless_vpc.id
  tags   = { Name = "Serverless-IGW" }
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.serverless_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pub_1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.pub_2.id
  route_table_id = aws_route_table.rt.id
}
