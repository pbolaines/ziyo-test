resource "aws_security_group" "patricia_sg" { ###This is the security group###
  name        = "allow traffic"
  description = "allow inbound traffic"
  vpc_id      = aws_vpc.patricia_vpc.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "patricia_instance" { ###This is the ec2 resource###
  ami           = "ami-0533f2ba8a1995cf9"
  instance_type = "t3.nano"

  monitoring    = true
  ebs_optimized = true

  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.patricia_sg.id]
  associate_public_ip_address = true

  tags = {
    Name : "Patricia-c2"
  }
}

resource "aws_vpc" "patricia_vpc" { ###This is the VPC with 2 subnets in different zones###
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Patricia VPC"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.patricia_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public Subnet"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.patricia_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public Subnet Two"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.patricia_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"

  tags = {
    Name = "Private Subnet"
  }
}

resource "aws_internet_gateway" "internet_ig" {
  vpc_id = aws_vpc.patricia_vpc.id

  tags = {
    Name = "Internet Gateway"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.patricia_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_ig.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_nat_gateway" "nat_gateway" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.private_subnet.id
}