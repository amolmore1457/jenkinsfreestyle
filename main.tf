provider "aws" {
  region = var.region
}

variable "region" {
  description = "AWS region"
  default     = "ap-south-1"  # Set your default region or leave it blank
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones for subnets"
  type        = list(string)
  default     = ["ap-south-1a", "ap-south-1b"]  # Add more availability zones as needed
}

locals {
  vpc_tags = {
    Name = "MyVPC"
  }

  public_subnet_cidr_blocks = [
    "${cidrsubnet(var.vpc_cidr_block, 8, 1)}",  # /24 for the first public subnet
    "${cidrsubnet(var.vpc_cidr_block, 8, 2)}",  # /24 for the second public subnet
  ]

  private_subnet_cidr_blocks = [
    "${cidrsubnet(var.vpc_cidr_block, 8, 3)}",  # /24 for the first private subnet
    "${cidrsubnet(var.vpc_cidr_block, 8, 4)}",  # /24 for the second private subnet
  ]
}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr_block

  tags = local.vpc_tags
}

resource "aws_subnet" "public_subnet" {
  count = length(local.public_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = local.public_subnet_cidr_blocks[count.index]
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "PublicSubnet-${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnet" {
  count = length(local.private_subnet_cidr_blocks)

  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = local.private_subnet_cidr_blocks[count.index]
  availability_zone       = element(var.availability_zones, count.index)

  tags = {
    Name = "PrivateSubnet-${count.index + 1}"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "PrivateRouteTable"
  }
}

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "MyIGW"
  }
}

resource "aws_route" "public_subnet_routes" {
  count                   = length(aws_subnet.public_subnet)
  route_table_id          = aws_route_table.public_route_table.id
  destination_cidr_block  = "0.0.0.0/0"
  gateway_id              = aws_internet_gateway.my_igw.id
  //subnet_id               = aws_subnet.public_subnet[count.index].id
}
resource "aws_nat_gateway" "my_nat_gateway" {
  count             = length(aws_subnet.public_subnet)
  allocation_id     = aws_eip.my_eip[count.index].id
  subnet_id         = aws_subnet.public_subnet[count.index].id
}

resource "aws_eip" "my_eip" {
  count = length(aws_subnet.public_subnet)
}

resource "aws_route" "private_subnet_routes" {
  count                   = length(aws_subnet.private_subnet)
  route_table_id          = aws_route_table.private_route_table.id
  destination_cidr_block  = "0.0.0.0/0"
  nat_gateway_id          = aws_nat_gateway.my_nat_gateway[count.index].id
  //subnet_id               = aws_subnet.private_subnet[count.index].id
}
resource "aws_instance" "public_instance" {
  count         = length(aws_subnet.public_subnet)
  ami           = "ami-0aee0743bf2e81172"  # Replace with your desired AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet[count.index].id
  //key_name      = "25thsept.pem"  # Replace with your key pair name

  tags = {
    Name = "PublicInstance-${count.index + 1}"
  }
}

resource "aws_instance" "private_instance" {
  count         = length(aws_subnet.private_subnet)
  ami           = "ami-0aee0743bf2e81172"  # Replace with your desired AMI ID
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet[count.index].id
  //key_name      = "C:\Users\Surbhi\Downloads\ethans_devops\terraform\practice\Assignment5\25thsept.pem"  # Replace with your key pair name

  tags = {
    Name = "PrivateInstance-${count.index + 1}"
  }
}

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.my_vpc.id
}

output "public_subnet_ids" {
  description = "IDs of the created public subnets"
  value       = aws_subnet.public_subnet[*].id
}

output "private_subnet_ids" {
  description = "IDs of the created private subnets"
  value       = aws_subnet.private_subnet[*].id
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public_route_table.id
}

output "private_route_table_id" {
  description = "ID of the private route table"
  value       = aws_route_table.private_route_table.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.my_igw.id
}