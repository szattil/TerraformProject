terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "eu-central-1"
}


resource "aws_s3_bucket" "bucket_for_terraform" {
  bucket = "bucket-for-terraform"
}

resource "aws_instance" "bucketcloud" {
  ami     = "ami-01e444924a2233b07"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  
}

# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}