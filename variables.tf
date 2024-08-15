variable "region" {
  description = "The AWS region to deploy to"
  default     = "eu-central-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "ami_id" {
  description = "The AMI ID to use for the EC2 instance"
  default     = "ami-0caef02b518350c8b"  # Ubuntu 20.04 LTS
}

variable "key_name" {
  description = "The name of the EC2 key pair"
}

variable "db_username" {
  description = "Username for the RDS database"
}

variable "db_password" {
  description = "Password for the RDS database"
}

variable "nextcloud_admin_user" {
  description = "Nextcloud admin username"
}

variable "nextcloud_admin_password" {
  description = "Nextcloud admin password"
}

variable "subdomain" {
  description = "The subdomain for the Nextcloud instance"
  default     = "cloud"
}

variable "domain_name" {
  description = "The domain name for the Nextcloud instance"
}

variable "route53_zone_id" {
  description = "The Route53 zone ID"
}