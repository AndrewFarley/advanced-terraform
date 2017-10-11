#
# Create a VPC - v1
# Basic example creating a VPC manually, generally you want to shy away
# from this kind-of manual creation of resources though in favor of modules,
# either created by you or others.  Don't use this terraform, please  :)
# 
provider "aws" {
  region = "${var.region}"
}

# Create our 
resource "aws_vpc" "vpc_tuto" {
  cidr_block = "172.31.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "TestVPC"
  }
}

# Public subnet
resource "aws_subnet" "public_subnet_eu_west_1a" {
  vpc_id                  = "${aws_vpc.vpc_tuto.id}"
  cidr_block              = "172.31.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "eu-west-1a"
  tags = {
  	Name =  "Subnet az 1a"
  }
}

# Private subnets
resource "aws_subnet" "private_1_subnet_eu_west_1a" {
  vpc_id                  = "${aws_vpc.vpc_tuto.id}"
  cidr_block              = "172.31.2.0/24"
  availability_zone = "eu-west-1a"
  tags = {
  	Name =  "Subnet private 1 az 1a"
  }
}
resource "aws_subnet" "private_2_subnet_eu_west_1a" {
  vpc_id                  = "${aws_vpc.vpc_tuto.id}"
  cidr_block              = "172.31.3.0/24"
  availability_zone = "eu-west-1a"
  tags = {
  	Name =  "Subnet private 2 az 1a"
  }
}

# Internet gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc_tuto.id}"
  tags {
        Name = "InternetGateway"
    }
}

# Route to the internet
resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.vpc_tuto.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.gw.id}"
}

# NAT Gateway
resource "aws_eip" "tuto_eip" {
  vpc      = true
  depends_on = ["aws_internet_gateway.gw"]
}
resource "aws_nat_gateway" "nat" {
    allocation_id = "${aws_eip.tuto_eip.id}"
    subnet_id = "${aws_subnet.public_subnet_eu_west_1a.id}"
    depends_on = ["aws_internet_gateway.gw"]
}

# Private route table and route to the internet
resource "aws_route_table" "private_route_table" {
    vpc_id = "${aws_vpc.vpc_tuto.id}"

    tags {
        Name = "Private route table"
    }
}
resource "aws_route" "private_route" {
	route_table_id  = "${aws_route_table.private_route_table.id}"
	destination_cidr_block = "0.0.0.0/0"
	nat_gateway_id = "${aws_nat_gateway.nat.id}"
}



# Associate subnet public_subnet_eu_west_1a to public route table
resource "aws_route_table_association" "public_subnet_eu_west_1a_association" {
    subnet_id = "${aws_subnet.public_subnet_eu_west_1a.id}"
    route_table_id = "${aws_vpc.vpc_tuto.main_route_table_id}"
}

# Associate subnet private_1_subnet_eu_west_1a to private route table
resource "aws_route_table_association" "pr_1_subnet_eu_west_1a_association" {
    subnet_id = "${aws_subnet.private_1_subnet_eu_west_1a.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}

# Associate subnet private_2_subnet_eu_west_1a to private route table
resource "aws_route_table_association" "pr_2_subnet_eu_west_1a_association" {
    subnet_id = "${aws_subnet.private_2_subnet_eu_west_1a.id}"
    route_table_id = "${aws_route_table.private_route_table.id}"
}