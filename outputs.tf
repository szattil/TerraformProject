output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.nextcloud_vpc.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "nextcloud_url" {
  description = "The URL of the Nextcloud instance"
  value       = "https://${aws_route53_record.nextcloud.name}"
}

output "ec2_instance_public_ip" {
  description = "The public IP of the EC2 instance"
  value       = aws_instance.nextcloud.public_ip
}

output "load_balancer_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.nextcloud.dns_name
}