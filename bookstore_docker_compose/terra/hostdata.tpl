#! /bin/bash
yum update -y
amazon-linux-extras install docker
service docker start
systemctl enable docker
usermod -a -G docker ec2-user
newgrp docker
chmod +x /usr/local/bin/docker-compose 
yum install git -y
TOKEN= ${mytoken}
cd /home/ec2-user && git clone https://$TOKEN@github.com/polilies/phonebook.git
#python3 /home/ec2-user/phonebook/phonebook-app.py
docker-compose up -d