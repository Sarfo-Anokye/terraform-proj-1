provider "aws" {
  region = "us-east-1"
}

#VPC
resource "aws_vpc" "testing-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "test-vpc"
  }
}

#INTERNET-GATEWAY
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.testing-vpc.id

  tags = {
    Name = "igw"
  }
}

#PRIVATE-SUBNET
resource "aws_subnet" "my_private_subnet" {
  vpc_id     = aws_vpc.testing-vpc.id
   availability_zone = "us-east-1b"
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = false    
  tags = {
    Name = "my-private-subnet"
  }
}
resource "aws_subnet" "my_private_subnet2" {
  vpc_id     = aws_vpc.testing-vpc.id
   availability_zone = "us-east-1a"
  cidr_block = "10.0.3.0/24"
  map_public_ip_on_launch = false    
  tags = {
    Name = "my-private-subnet2"
  }
}

#PUBLIC-SUBNET
resource "aws_subnet" "my_public_subnet" {
  vpc_id     = aws_vpc.testing-vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true    
  tags = {
    Name = "my-public-subnet"
  }
}

#PUBLIC-ROUTE-TABLE
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.testing-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
  }


  tags = {
    Name = "public-rt"
  }
}

#PUBLIC-RT-ATTACH
resource "aws_route_table_association" "rt-association" {
  subnet_id      = aws_subnet.my_public_subnet.id
  route_table_id = aws_route_table.public-rt.id
}

#AMI-DATA-SOURCE
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

#EC2
resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = aws_subnet.my_public_subnet.id

  tags = {
    Name = "my-ec2"
  }
}

#DB-SUBNET-GROUP
resource "aws_db_subnet_group" "db-subnet-grp" {
  name       = "private-subnet-grp"
  subnet_ids = [aws_subnet.my_private_subnet.id,aws_subnet.my_private_subnet2.id]

  tags = {
    Name = "My DB subnet group"
  }
}

#RDS-INSTANCE
resource "aws_db_instance" "my-db-instance" {
  allocated_storage    = 10
  db_name              = "mydb"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = "admin123"
  db_subnet_group_name = aws_db_subnet_group.db-subnet-grp.name
  skip_final_snapshot  = true
  publicly_accessible  = false

    tags = {
    Name = "my-rds-instance"
  }
}