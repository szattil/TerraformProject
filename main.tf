# Provider configuration
provider "aws" {
  region = var.region
}

# Random string for unique naming
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# VPC
resource "aws_vpc" "nextcloud_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "nextcloud-vpc-${random_string.suffix.result}"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "nextcloud_igw" {
  vpc_id = aws_vpc.nextcloud_vpc.id

  tags = {
    Name = "nextcloud-igw-${random_string.suffix.result}"
  }
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.nextcloud_vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "nextcloud-public-subnet-${count.index + 1}"
  }
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.nextcloud_vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "nextcloud-private-subnet-${count.index + 1}"
  }
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.nextcloud_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.nextcloud_igw.id
  }

  tags = {
    Name = "nextcloud-public-rt"
  }
}

# Route Table Association for Public Subnets
resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ACM Certificate
resource "aws_acm_certificate" "nextcloud_cert" {
  domain_name       = "${var.subdomain}.${var.domain_name}"
  validation_method = "DNS"

  tags = {
    Name = "NextcloudCertificate"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 record for certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.nextcloud_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.route53_zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.nextcloud_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Application Load Balancer
resource "aws_lb" "nextcloud" {
  name               = "nextcloud-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nextcloud_lb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name = "NextcloudLoadBalancer"
  }
}

# ALB Target Group
resource "aws_lb_target_group" "nextcloud" {
  name     = "nextcloud-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.nextcloud_vpc.id

  health_check {
    enabled             = true
    interval            = 30
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# ALB Listener (HTTP)
resource "aws_lb_listener" "nextcloud_http" {
  load_balancer_arn = aws_lb.nextcloud.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ALB Listener (HTTPS)
resource "aws_lb_listener" "nextcloud_https" {
  load_balancer_arn = aws_lb.nextcloud.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.nextcloud_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nextcloud.arn
  }
}

# RDS MySQL Instance
resource "aws_db_instance" "nextcloud_db" {
  identifier           = "nextcloud-db-${random_string.suffix.result}"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  allocated_storage    = 20
  storage_type         = "gp2"
  db_name              = "nextcloud"
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.nextcloud_db.id]
  db_subnet_group_name   = aws_db_subnet_group.nextcloud.name
}

# DB Subnet Group
resource "aws_db_subnet_group" "nextcloud" {
  name       = "nextcloud-db-subnet-group"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "NextcloudDBSubnetGroup"
  }
}

# EC2 Instance
resource "aws_instance" "nextcloud" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.key_name
  subnet_id     = aws_subnet.public[0].id

  vpc_security_group_ids = [aws_security_group.nextcloud.id]

  tags = {
    Name = "NextcloudServer-${random_string.suffix.result}"
  }

  user_data = <<-EOF
              #!/bin/bash
              exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
              echo "Starting user data script execution"

              echo "Updating system packages"
              sudo apt-get update
              sudo apt-get upgrade -y

              echo "Installing Docker"
              sudo apt-get install -y docker.io
              sudo systemctl start docker
              sudo systemctl enable docker
              echo "Docker installed and started"

              echo "Installing Docker Compose"
              sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
              sudo chmod +x /usr/local/bin/docker-compose
              echo "Docker Compose installed"

              echo "Creating Docker Compose file for Nextcloud"
              cat <<EOT > /home/ubuntu/docker-compose.yml
              version: '3'
              services:
                nextcloud:
                  image: nextcloud
                  ports:
                    - 80:80
                  volumes:
                    - nextcloud:/var/www/html
                  environment:
                    - NEXTCLOUD_ADMIN_USER=${var.nextcloud_admin_user}
                    - NEXTCLOUD_ADMIN_PASSWORD=${var.nextcloud_admin_password}
                    - NEXTCLOUD_TRUSTED_DOMAINS=${var.subdomain}.${var.domain_name}
                    - MYSQL_HOST=${aws_db_instance.nextcloud_db.endpoint}
                    - MYSQL_DATABASE=${aws_db_instance.nextcloud_db.db_name}
                    - MYSQL_USER=${var.db_username}
                    - MYSQL_PASSWORD=${var.db_password}
              volumes:
                nextcloud:
              EOT

              echo "Starting Nextcloud container"
              sudo docker-compose -f /home/ubuntu/docker-compose.yml up -d
              echo "Nextcloud container started"

              echo "User data script execution completed"
              EOF
}

# ALB Target Group Attachment
resource "aws_lb_target_group_attachment" "nextcloud" {
  target_group_arn = aws_lb_target_group.nextcloud.arn
  target_id        = aws_instance.nextcloud.id
  port             = 80
}

# Security Group for Load Balancer
resource "aws_security_group" "nextcloud_lb" {
  name        = "nextcloud-lb-sg"
  description = "Security group for Nextcloud load balancer"
  vpc_id      = aws_vpc.nextcloud_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for EC2 Instance
resource "aws_security_group" "nextcloud" {
  name        = "nextcloud_sg_${random_string.suffix.result}"
  description = "Security group for Nextcloud server"
  vpc_id      = aws_vpc.nextcloud_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.nextcloud_lb.id]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.nextcloud_lb.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for RDS
resource "aws_security_group" "nextcloud_db" {
  name        = "nextcloud_db_sg_${random_string.suffix.result}"
  description = "Security group for Nextcloud database"
  vpc_id      = aws_vpc.nextcloud_vpc.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.nextcloud.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_route53_record" "nextcloud" {
  zone_id = var.route53_zone_id
  name    = "${var.subdomain}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.nextcloud.dns_name
    zone_id                = aws_lb.nextcloud.zone_id
    evaluate_target_health = true
  }
}

# Data source for available AZs
data "aws_availability_zones" "available" {
  state = "available"
}