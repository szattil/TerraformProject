# TerraformProject

Creates an AWS instance and installs Nextcloud in a Docker container. The connection it creates is secure.

Generates an RDS MySQL database, and an EC2 instance with load balancer and security groups.
Before use generate a key pair and a Route53 access yourself.

Use the terraform.tfvars file for your own variables.


The EC2 and DB instances are within the free tier (they are in variables.tf and main.tf respectively if you want to pay more).
Route53 and the Load Balancer solution should cost some penny so be careful.
