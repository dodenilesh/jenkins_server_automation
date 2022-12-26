# Private VPC/Subnets/Route Table/IG creation

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_vpc
  enable_dns_support   = true
  enable_dns_hostnames = true


  tags = {
    Environment = "${var.environment_tag}"
    Name        = "TerraformVpc"
  }
}

resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_subnet1_cidr
  map_public_ip_on_launch = "true"
  availability_zone       = element(var.az, 0)
  tags = {
    Environment = "${var.environment_tag}"
    Name        = element(var.subnet_names, 0)
  }

}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Terraform_IG"
  }
}


resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "TerraformRouteTable"
  }
}


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.route_table.id
}
