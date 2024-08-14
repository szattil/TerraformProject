variable "region" {
  default = "eu-central-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "ami_id" {
  default = "ami-0caef02b518350c8b" # Ubuntu 20.04 LTS
}

variable "instance_type" {
  default = "t2.micro"
}

variable "key_name" {
  description = "Name of the EC2 key pair"
}

variable "domain" {
  default = "flumorstasis.hu"
}

variable "db_name" {
  default = "nextcloud"
}

variable "db_username" {
  description = "Database username"
}

variable "db_password" {
  description = "Database password"
}

variable "nextcloud_admin_password" {
  description = "Initial Nextcloud admin password"
  sensitive   = true
}

variable "existing_ec2_instance_id" {
  description = "ID of an existing EC2 instance to use for IP whitelisting"
  type        = string
  default     = ""
}