provider "aws" {
  region = var.region
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "aws_db_instance" "nextcloud_db" {
  identifier           = "nextcloud-db"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"  // Free tier eligible
  allocated_storage    = 20
  storage_type         = "gp2"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = "default.mysql8.0"
  skip_final_snapshot  = true
  publicly_accessible  = false
  vpc_security_group_ids = [aws_security_group.db.id]
}

resource "aws_security_group" "db" {
  name        = "nextcloud_db_sg"
  description = "Allow inbound traffic from EC2 to RDS"

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

resource "aws_instance" "nextcloud" {
  ami           = var.ami_id
  instance_type = "t2.micro"  // Free tier eligible
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.nextcloud.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y docker.io docker-compose
              sudo systemctl start docker
              sudo systemctl enable docker
              
              cat <<EOT > /home/ubuntu/docker-compose.yml
              version: '3'
              services:
                nextcloud:
                  image: nextcloud
                  restart: always
                  ports:
                    - "80:80"
                  volumes:
                    - nextcloud:/var/www/html
                  environment:
                    - NEXTCLOUD_ADMIN_USER=${var.nextcloud_admin_user}
                    - NEXTCLOUD_ADMIN_PASSWORD=${var.nextcloud_admin_password}
                    - NEXTCLOUD_TRUSTED_DOMAINS=${var.subdomain}.${var.domain_name}
                    - MYSQL_HOST=${aws_db_instance.nextcloud_db.endpoint}
                    - MYSQL_DATABASE=${var.db_name}
                    - MYSQL_USER=${var.db_username}
                    - MYSQL_PASSWORD=${var.db_password}

              volumes:
                nextcloud:
              EOT
              
              sudo docker-compose -f /home/ubuntu/docker-compose.yml up -d
              EOF

  tags = {
    Name = "NextcloudServer-${random_string.suffix.result}"
  }
}

resource "aws_security_group" "nextcloud" {
  name        = "nextcloud_sg"
  description = "Security group for Nextcloud server"

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