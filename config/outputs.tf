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

output "ssl_cert_arn" {
  value = aws_acm_certificate.cert.arn
}

output "public_ip" {
  value       = aws_instance.example.public_ip
  description = "The public IP of the web server"
}