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