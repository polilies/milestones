#! /bin/bash
yum update -y
amazon-linux-extras install docker
service docker start
systemctl enable docker
usermod -a -G docker ec2-user
newgrp docker
chmod +x /usr/local/bin/docker-compose