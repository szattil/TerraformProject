output "nextcloud_url" {
  value = "http://cloud.flumorstasis.hu"
}

output "ec2_public_ip" {
  value = aws_instance.nextcloud.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.nextcloud_db.endpoint
}

output "route53_nameservers" {
  value = aws_route53_zone.main.name_servers
}