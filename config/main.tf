# Terraform configuration

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.25.0"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = var.vpc_name
  cidr = var.vpc_cidr_block

  azs             = var.vpc_azs
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, var.private_subnet_count)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.1.2"
  name          = "ec2-go-getweather"

  ami           = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.go-getweather.id]
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

resource "aws_autoscaling_group" "go-getweather" {
  name                 = "go-getweather-ag"  
  launch_configuration = module.ec2_instance.id
  load_balancers       = ["${aws_elb.elb.name}"]
  availability_zones   = ["us-east-1b", "us-east-1a", "us-east-1c"]
  min_size             = 1
  max_size             = 2

  tag {
    key                 = "go-getweather"
    value               = "terraform-go-asg"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "elb" {
  name = "terraform-go-api"

  # Inbound HTTP from anywhere
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

    health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    target              = "HTTP:8080/"
  }
}

resource "aws_elb" "elb" {
  name               = "go-getweather-elb"
  availability_zones = ["us-east-1b", "us-east-1a", "us-east-1c"]
  security_groups    = ["${aws_security_group.elb.id}"]

    listener {
    lb_port           = 8080
    lb_protocol       = "http"
    instance_port     = 8080
    instance_protocol = "http"
  }
}