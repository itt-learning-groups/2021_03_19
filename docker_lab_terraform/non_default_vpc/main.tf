# RESOURCES:
# 1 non-default VPC, associated with
# 1 internet gateway

# OUTPUTS (needed for next step):
# VPC ID
# internet gateway ID

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

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
    Vpc  = "main"
  }
}

# e.g. terraform output main_vpc_id
output "main_vpc_id" {
  value       = aws_vpc.main.id
  description = "main VPC ID"
}

# e.g. terraform output internet_gateway_id
output "internet_gateway_id" {
  value       = aws_internet_gateway.igw.id
  description = "internet gateway ID"
}
