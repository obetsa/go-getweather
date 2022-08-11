# Terraform configuration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.0.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.11.0"

  name = var.vpc_name
  cidr = var.vpc_cidr_block

  azs             = var.vpc_azs
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, var.private_subnet_count)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)

  enable_nat_gateway = var.vpc_enable_nat_gateway
  enable_vpn_gateway = var.enable_vpn_gateway
}

module "ec2_instances" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.12.0"
  vpc_id = module.vpc.vpc_id
  name          = "ec2-go-getweather"

  ami           = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]
  subnet_id              = module.vpc.public_subnets[0]

  user_data = <<-EOF
              #!/bin/bash
              sudo su
              sudo yum update -y
              sudo yum install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo docker run -d --restart always -p 8080:8080 obetsa/go-getweather:latest
              EOF

  tags = {
    Name        = "ec2-go-getweather"
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_security_group" "go-getweather" {
  name = "go-getweather"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "tls_private_key" "go" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "go" {
  key_algorithm   = "RSA"
  private_key_pem = tls_private_key.go.private_key_pem

  subject {
    common_name  = "hashicups.com"
    organization = "HashiCups, Inc"
  }

  validity_period_hours = 60

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "aws_acm_certificate" "cert" {
  private_key      = tls_private_key.go.private_key_pem
  certificate_body = tls_self_signed_cert.go.cert_pem
}