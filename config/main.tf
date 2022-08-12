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

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = var.vpc_name
  cidr = var.vpc_cidr_block

  azs             = var.vpc_azs
  private_subnets = slice(var.private_subnet_cidr_blocks, 0, var.private_subnet_count)
  public_subnets  = slice(var.public_subnet_cidr_blocks, 0, var.public_subnet_count)
  enable_dns_hostnames = true
  enable_dns_support   = true

  enable_nat_gateway = var.vpc_enable_nat_gateway

  tags = var.vpc_tags
}

module "ec2_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.1.2"
  name          = "ec2-go-getweather"

  ami           = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  key_name      = "go"
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

module "ec2_cluster" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "4.1.2"

  name          = "my-cluster-pr"
  count         = 3

  ami           = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  key_name      = "go"
  monitoring             = true
  vpc_security_group_ids = [aws_security_group.go-getweather.id]
  subnet_id              = module.vpc.private_subnets[0]
  associate_public_ip_address = "false"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_eip" "go-elp" {
  instance = module.ec2_instance.id
  vpc      = true
}

resource "aws_security_group" "go-getweather-sg" {
  name = "go-getweather-sg"
  vpc_id   = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    from_port   = 22
    to_port     = 22
    description = ""
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

resource "aws_launch_configuration" "go-getweather-lc" {
  name            = "ec2-lb-asg"
  image_id        = "ami-090fa75af13c156b4"
  instance_type   = "t2.micro"
  key_name        = "go"
  security_groups = [aws_security_group.go-getweather-sg.id]
  user_data = <<-EOF
              #!/bin/bash
              sudo su
              sudo yum update -y
              sudo yum install docker -y
              sudo service docker start
              sudo usermod -a -G docker ec2-user
              sudo docker run -d --restart always -p 80:8080 obetsa/go-getweather:latest
              EOF
  lifecycle {
    create_before_destroy = true
  }

  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("/home/ec2-user/keys/aws/aws_key")
    timeout     = "4m"
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

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_autoscaling_group" "go-getweather-ag" {
  name                 = "go-getweather-ag"  
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  launch_configuration = aws_launch_configuration.go-getweather-lc.id
  vpc_zone_identifier  = module.vpc.public_subnets

  tag {
    key                 = "Name"
    value               = "terraform-go-asg"
    propagate_at_launch = true
  }
}

resource "aws_lb" "lb" {
  name               = "go-getweather-elb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.elb.id}"]
  subnets            = module.vpc.public_subnets
}

resource "aws_lb_listener" "go-list" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.go-tg.arn
  }
}

resource "aws_lb_target_group" "go-tg" {
  name     = "go-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.vpc.vpc_id

}

resource "aws_autoscaling_attachment" "go-acs-att" {
  autoscaling_group_name = aws_autoscaling_group.go-getweather-ag.id
  lb_target_group_arn   = aws_lb_target_group.go-tg.arn
}

resource "aws_security_group" "go-getweather_instance" {
  name = "go-getweather_instance"
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.elb.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.elb.id]
  }

  vpc_id = module.vpc.vpc_id
}

resource "aws_security_group" "elb" {
  name = "terraform-go-api"

  # Inbound HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
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

  vpc_id = module.vpc.vpc_id

}

module "website_s3_bucket" {
  source = "./modules/aws-s3-static-website-bucket"

  bucket_name = "obetsa-go-getweather"

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}