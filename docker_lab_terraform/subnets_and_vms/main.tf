# (VARIABLE) INPUTS:
# 1 SSH key imported into the AWS account
# 1 "main" VPC ID
# 1 "main" VPC internet gateway ID

# RESOURCES:
# 1 public subnet,
# with 1 NAT gateway and its elastic IP,
# associated with 1 non-default route table that has a route to the internet (CIDR 0.0.0.0/0) via the internet gateway

# 1 private subnet,
# associated with 1 non-default route table that has a route to the internet (CIDR 0.0.0.0/0) via the NAT gateway

# 1 security group allowing ingress on port 22 (SSH) and from any other member of the same security group

# 1 AWS linux2 (centos) virtual machine with Docker installed (the “docker lab” instance) with no public IP address but with a private IP address (created in the private subnet, protected by the security group, and with the SSH key associated)
# 1 “bastion” host AWS linux2 (centos) virtual machine with a public IP address (created in the public subnet, protected by the security group, and with the SSH key associated)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_subnet" "main_vpc_public_2a" {
  vpc_id            = var.main_vpc_id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name          = "main-vpc-public-2a"
    Vpc           = "main"
    Accessibility = "public"
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true

  tags = {
    Name = "main-vpc-nat-gateway"
    Vpc  = "main"
  }
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.main_vpc_public_2a.id

  tags = {
    Name = "main-vpc-nat-gateway"
    Vpc  = "main"
  }
}

resource "aws_route_table" "public_subnet" {
  vpc_id = var.main_vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.igw_id
  }

  tags = {
    Name = "main-vpc-public-rt"
    Vpc  = "main"
  }
}

resource "aws_route_table_association" "public_subnet" {
  subnet_id = aws_subnet.main_vpc_public_2a.id
  route_table_id = aws_route_table.public_subnet.id
}

resource "aws_subnet" "main_vpc_private_2a" {
  vpc_id            = var.main_vpc_id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name          = "main-vpc-private-2a"
    Vpc           = "main"
    Accessibility = "private"
  }
}

resource "aws_route_table" "private_subnet" {
  vpc_id = var.main_vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id
  }

  tags = {
    Name = "main-vpc-private-rt"
    Vpc  = "main"
  }
}

resource "aws_route_table_association" "private_subnet" {
  subnet_id = aws_subnet.main_vpc_private_2a.id
  route_table_id = aws_route_table.private_subnet.id
}

resource "aws_security_group" "allow_ssh" {
  name = "allow-ssh"
  description = "allow SSH access for developers"
  vpc_id = var.main_vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${var.ssh_ip}/32"]
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port = 0
    to_port = 0
    protocol = "-1"
  }

  tags = {
    Name = "main-vpc-allow-ssh"
    Vpc  = "main"
  }
}

resource "aws_security_group_rule" "allow_ssh_self" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.allow_ssh.id
  self              = true
}

resource "aws_instance" "bastion" {
  instance_type               = "t2.micro"
  ami                         = "ami-09c5e030f74651050"
  subnet_id                   = aws_subnet.main_vpc_public_2a.id
  security_groups             = [aws_security_group.allow_ssh.id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_size = "8"
  }

  tags = {
    Name = "main-vpc-bastion-host"
    Vpc  = "main"
  }
}

resource "aws_instance" "docker_lab" {
  instance_type               = "t2.micro"
  ami                         = "ami-09c5e030f74651050"
  subnet_id                   = aws_subnet.main_vpc_private_2a.id
  security_groups             = [aws_security_group.allow_ssh.id]
  key_name                    = var.key_name
  associate_public_ip_address = false

  root_block_device {
    volume_size = "8"
  }

  user_data = "${file("install_docker.sh")}"

  tags = {
    Name = "main-vpc-docker-lab"
    Vpc  = "main"
  }
}

# e.g. terraform output bastion_host_public_ip
output "bastion_host_public_ip" {
  value = aws_instance.bastion.public_ip
}

# e.g. terraform output docker_lab_private_ip
output "docker_lab_private_ip" {
  value = aws_instance.docker_lab.private_ip
}
