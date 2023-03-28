#! /bin/bash
yum update -y
amazon-linux-extras install docker
service docker start
systemctl enable docker
usermod -a -G docker ec2-user
newgrp docker
curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose 
#yum install git -y
yum install wget
cd /home/ec2-user/
mkdir bookstore && cd bookstore
wget -O Dockerfile https://raw.githubusercontent.com/polilies/bookstore_project/main/Dockerfile
wget -O docker-compose.yml https://raw.githubusercontent.com/polilies/bookstore_project/main/docker-compose.yml
#cd vol
wget -O bookstore-api.py https://raw.githubusercontent.com/polilies/bookstore_project/main/bookstore-api.py
wget -O requirements.txt https://raw.githubusercontent.com/polilies/bookstore_project/main/requirements.txt
#python3 /home/ec2-user/phonebook/phonebook-app.py
docker-compose --project-name bookstore up