output "alb_dns_name" {
  value       = aws_lb.web.dns_name
}

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "db_subnet_ids" {
  value = aws_subnet.db[*].id
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.main[*].id
}

output "asg_name" {
  value = aws_autoscaling_group.web.name
}

output "db_endpoint" {
  value       = aws_db_instance.main.address
}

output "db_master_secret_arn" {
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}
