# Output variable definitions

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
  description = "IDs of the VPC's public subnets"
}

output "go-getweather" {
  value = aws_security_group.go-getweather.id
}

output "public_ip" {
  value       = module.ec2_instance.public_ip
  description = "The public IP of the web server"
}

output "elb_dns_name" {
  value = "${aws_lb.lb.dns_name}"
}