# create a vpc

resource "aws_vpc" "my_vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}
# create an internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# use data source to get all availability zones in region
data "aws_availability_zones" "azs" {}


# create 2 public subnets
resource "aws_subnet" "public-1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public1_subnet_cidr
  availability_zone = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-1"
  }
}

resource "aws_subnet" "public-2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.public2_subnet_cidr
  availability_zone = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-2"
  }
  
}

# create a custom route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

# associate public_1 with route table
resource "aws_route_table_association" "public_1_association" {
  subnet_id      = aws_subnet.public-1.id
  route_table_id = aws_route_table.public_rt.id
}

# associate public_2 with route table
resource "aws_route_table_association" "public_2_association" {
  subnet_id      = aws_subnet.public-2.id
  route_table_id = aws_route_table.public_rt.id
}

# create 2 private app subnets
resource "aws_subnet" "app-1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.app1_subnet_cidr
  availability_zone = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "app-1"
  }
}

resource "aws_subnet" "app-2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.app2_subnet_cidr
  availability_zone = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "app-2"
  }
  
}

# create 2 private data subnets
resource "aws_subnet" "data-1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.data1_subnet_cidr
  availability_zone = data.aws_availability_zones.azs.names[0]
  map_public_ip_on_launch = false

  tags = {
    Name = "data-1"
  }
}

resource "aws_subnet" "data-2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.data2_subnet_cidr
  availability_zone = data.aws_availability_zones.azs.names[1]
  map_public_ip_on_launch = false

  tags = {
    Name = "data-2"
  }
  
}


