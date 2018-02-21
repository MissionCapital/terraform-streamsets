#=============================================
# Basic VPC setup
#=============================================

# Create a VPC to launch our instances into
resource "aws_vpc" "default" {
  cidr_block = "${var.vpc_cidr}"
  tags {
    Name = "${var.name_prefix}-vpc"
  }
}

# Create an internet gateway to give our subnets access to the outside world
resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"
  tags {
    Name = "${var.name_prefix}-igw"
  }
}

#=============================================
# Public Subnet Setup
#=============================================

# create a public subnet for things like the ELB and bastion
resource "aws_subnet" "public" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${var.public_subnet_cidr}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.name_prefix}-public-subnet"
  }
}

# create the route table for this subnet, pointed at internet gateway
resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.default.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }

  tags {
    Name = "${var.name_prefix}-public-route-table"
  }
}

# link the two together
resource "aws_route_table_association" "public" {
  subnet_id = "${aws_subnet.public.id}"
  route_table_id = "${aws_route_table.public.id}"
}

#=============================================
# NAT Gateway Setup
#=============================================

# create a public IP for the NAT gateway
resource "aws_eip" "nat" {
  vpc = true
}

# used to route internet traffic for our private subnets
resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id = "${aws_subnet.public.id}"

  tags {
    Name = "${var.name_prefix}-nat-gateway"
  }

  depends_on = ["aws_internet_gateway.default"]
}

#=============================================
# Default VPC Route Table
#=============================================

# Set up the default route table to point to the NAT gateway.
# This way, any new resources point there instead of the outside world
# (helps prevent mistakes)
resource "aws_default_route_table" "r" {
  default_route_table_id = "${aws_vpc.default.default_route_table_id}"

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }

  tags {
    Name = "${var.name_prefix}-default-route-table"
  }
}

#=============================================
# Private subnet setup
#=============================================

# create a private subnet for backend instances. This should take
# the default route table pointed to NAT gateway
resource "aws_subnet" "private" {
  vpc_id = "${aws_vpc.default.id}"
  cidr_block = "${var.private_subnet_cidr}"
  # no public IP's for this subnet - access through bastion
}
