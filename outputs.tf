output "nextcloud_url" {
  value = "https://cloud.${var.domain}"
}

output "ec2_public_ip" {
  value = aws_instance.nextcloud_server.public_ip
}

output "rds_endpoint" {
  value = aws_db_instance.nextcloud.endpoint
}

output "nextcloud_admin_info" {
  value = "Nextcloud admin username: admin, password: set in terraform.tfvars"
  sensitive = true
}