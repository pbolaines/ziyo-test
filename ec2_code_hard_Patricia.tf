resource "aws_security_group" "allow_https" { ###This is the security group###
  name        = "allow traffic"
  description = "allow inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "code_hardening_ec2_patricia" { ###This is the ec2###
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t3.micro"

  monitoring    = true
  ebs_optimized = true

  count                       = length(var.public_subnet_cidrs)
  subnet_id                   = element(aws_subnet.public_subnets[*].id, count.index)
  vpc_security_group_ids      = [aws_security_group.allow_https.id]
  associate_public_ip_address = true

  tags = {
    Name        = "ec2"
    Environment = "code_hardening"
  }
}

resource "aws_vpc" "main" { ###This is the VPC with 3 subnets in different zones###
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "Project VPC"
  }
}


variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["10.0.4.0/24"]
}

variable "east" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1b", "us-east-1c", "us-east-1d", "us-east-1e", "us-east-1f"]
}

resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.east, count.index)

  tags = {
    Name = "Public_Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.east, count.index)

  tags = {
    Name = "Private_Subnet ${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Project VPC IG"
  }
}

resource "aws_route_table" "second_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "2nd Route Table"
  }
}

resource "aws_route_table_association" "public_subnet_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.second_rt.id
}

resource "aws_nat_gateway" "nat_gateway" {
  connectivity_type = "private"
  count             = length(var.private_subnet_cidrs)
  subnet_id         = element(aws_subnet.private_subnets[*].id, count.index)
}


