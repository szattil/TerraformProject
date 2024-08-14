#!/bin/bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-compose
sudo systemctl start docker
sudo systemctl enable docker

# Create docker-compose.yml file
cat << EOT > /home/ubuntu/docker-compose.yml
version: '3'
services:
  nextcloud:
    image: nextcloud
    restart: always
    ports:
      - 80:80
    volumes:
      - nextcloud_data:/var/www/html
    environment:
      - MYSQL_HOST=${db_host}
      - MYSQL_DATABASE=${db_name}
      - MYSQL_USER=${db_user}
      - MYSQL_PASSWORD=${db_password}
      - NEXTCLOUD_TRUSTED_DOMAINS=cloud.${domain}
      - OVERWRITEPROTOCOL=https
  proxy:
    image: jwilder/nginx-proxy
    ports:
      - 80:80
      - 443:443
    volumes:
      - /var/run/docker.sock:/tmp/docker.sock:ro
      - certs:/etc/nginx/certs:ro
      - vhost:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html
    restart: always
  letsencrypt:
    image: jrcs/letsencrypt-nginx-proxy-companion
    volumes:
      - certs:/etc/nginx/certs:rw
      - vhost:/etc/nginx/vhost.d
      - html:/usr/share/nginx/html
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - NGINX_PROXY_CONTAINER=proxy
      - LETSENCRYPT_HOST=cloud.${domain}
    restart: always
volumes:
  nextcloud_data:
  certs:
  vhost:
  html:
EOT

# Run docker-compose
sudo docker-compose -f /home/ubuntu/docker-compose.yml up -d

# Wait for Nextcloud to be fully set up
sleep 60

# Create initial admin account
docker exec -u www-data -e OC_PASS=${nextcloud_admin_password} nextcloud php occ user:add --display-name="Initial Admin" --group="admin" admin