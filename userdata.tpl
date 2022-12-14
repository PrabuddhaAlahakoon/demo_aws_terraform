#!/bin/bash
sudo apt-get update -y &&
sudo apt-get install -y \
apt-transport-https \
ca-certificates \
curl \
gnupg-agent \
software-properties-common &&
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" &&
sudo apt-get update -y &&
sudo sudo apt-get install docker-ce docker-ce-cli containerd.io -y apache2 -y docker-compose -y &&
sudo usermod -aG docker ubuntu
sudo systemctl start apache2
sudo bash -c 'echo your very first web server > /var/www/html/index.html'
sudo bash -c cat << EOF > docker-compose.yml
version: '3.0'

services:
  mysqldb:
    image: mysql
    restart: unless-stopped
    ports:
      - 3307:3306
    environment:
      - MYSQL_ROOT_PASSWORD=1234567890
      - MYSQL_DATABASE=docker_demo
    volumes:
      - db:/var/lib/mysql

  springapp:
    depends_on:
      - mysqldb
    image: prabuddha66/docker-demo
    restart: on-failure
    ports:
      - 8080:8080
    environment:
      SPRING_APPLICATION_JSON: '{
        "spring.datasource.url":"jdbc:mysql://mysqldb:3306/docker_demo",
        "spring.datasource.username":"root",
        "spring.datasource.password":"1234567890",
        "spring.jpa.show-sql":"true",
        "spring.jpa.hibernate.ddl-auto":"update",
        "spring.jpa.properties.hibernate.dialect":"org.hibernate.dialect.MySQL5Dialect"
       }'
volumes:
  db:

EOF
sudo cd /
sudo docker-compose -f /docker-compose.yml up -d