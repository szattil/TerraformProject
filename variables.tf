variable "region" {
  default = "eu-central-1"
}

variable "ami_id" {
  default = "ami-0caef02b518350c8b" # Ubuntu 20.04 LTS
}

variable "key_name" {
  description = "Name of the EC2 key pair"
}

variable "db_name" {
  description = "Database name for Nextcloud"
  default     = "nextcloudDB"
}

variable "db_username" {
  description = "Database username for Nextcloud"
}

variable "db_password" {
  description = "Database password for Nextcloud"
}

variable "nextcloud_admin_user" {
  description = "Nextcloud admin username"
}

variable "nextcloud_admin_password" {
  description = "Nextcloud admin password"
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt notifications"
}

variable "route53_zone_id" {
  description = "ID of the existing Route53 zone"
  type        = string
}

variable "domain_name" {
  description = "The domain name for the Nextcloud instance"
  default     = "flumorstasis.hu"
}

variable "subdomain" {
  description = "The existing subdomain for the Nextcloud instance"
  type        = string
  default     = "cloud"
}