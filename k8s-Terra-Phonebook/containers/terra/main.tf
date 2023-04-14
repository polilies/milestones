# Please change the key_name and your config file 
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    github = {
      source  = "integrations/github"
      version = "5.18.3"
    }
  }
}

provider "github" {
  token = var.token # or `GITHUB_TOKEN`
}

provider "aws" {
  region = "us-east-1"
}

locals {
  instance-type       = "t2.micro"
  key-name            = "nvirginia"
  secgr-dynamic-ports = [22, 80, 443, 8080, 5000]
  user                = "polilies"
}

resource "github_repository" "k8s_phonebook_web" {
  name        = "k8s_phone"
  description = "docker-compose, docker build, terraform github repo creation, aws_ec2 "
  auto_init   = true
  visibility  = "public"
  #branch      = "main"
  /*   template {
    owner                = "github"
    repository           = "polilies  "
    include_all_branches = true
  } */
}

resource "github_repository_file" "web" {
  for_each            = toset(var.paths_web)
  content             = file("${var.basepath_web}/${each.value}")
  file                = "web/${each.value}"
  repository          = github_repository.k8s_phonebook_web.name
  overwrite_on_create = true
  branch              = "main"
}

resource "github_repository_file" "result" {
  for_each            = toset(var.paths_result)
  content             = file("${var.basepath_result}/${each.value}")
  file                = "result/${each.value}"
  repository          = github_repository.k8s_phonebook_web.name
  overwrite_on_create = true
  branch              = "main"
}


resource "aws_security_group" "allow_ssh" {
  name        = "${local.user}-docker-instance-sg"
  description = "Allow SSH inbound traffic"

  dynamic "ingress" {
    for_each = local.secgr-dynamic-ports
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    description = "Outbound Allowed"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "amazon-linux-2" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "owner-alias"
    values = ["amazon"]
  }
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm*"]
  }
}
resource "aws_instance" "tf-ec2" {
  ami                    = data.aws_ami.amazon-linux-2.id
  instance_type          = local.instance-type
  key_name               = "nvirginia"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
  tags = {
    Name = "Docker-instance"
  }
  user_data = <<-EOF
              #!/bin/bash
              hostnamectl set-hostname docker_instance
              yum update -y
              yum install docker -y
              systemctl start docker
              systemctl enable docker
              usermod -a -G docker ec2-user
              newgrp docker
              # install docker-compose
              curl -SL https://github.com/docker/compose/releases/download/v2.16.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
              ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
              cd /home/ec2-user/
              mkdir web && cd web
              mkdir templates
              wget -O Dockerfile https://raw.githubusercontent.com/polilies/k8s_phone/main/web/Dockerfile
              wget -O templates/add-update.html https://raw.githubusercontent.com/polilies/k8s_phone/main/web/add-update.html
              wget -O templates/delete.html https://raw.githubusercontent.com/polilies/k8s_phone/main/web/delete.html
              wget -O templates/index.html https://raw.githubusercontent.com/polilies/k8s_phone/main/web/index.html
              wget -O app.py https://raw.githubusercontent.com/polilies/k8s_phone/main/web/app.py
              wget -O requirements.txt https://raw.githubusercontent.com/polilies/k8s_phone/main/web/requirements.txt
              cd ..
              mkdir result && cd result
              mkdir templates
              wget -O Dockerfile https://raw.githubusercontent.com/polilies/k8s_phone/main/result/Dockerfile
              wget -O templates/index.html https://raw.githubusercontent.com/polilies/k8s_phone/main/result/index.html
              wget -O app.py https://raw.githubusercontent.com/polilies/k8s_phone/main/result/app.py
              wget -O requirements.txt https://raw.githubusercontent.com/polilies/k8s_phone/main/result/requirements.txt
	          EOF
}
output "myec2-public-ip" {
  value = aws_instance.tf-ec2.public_ip
}

output "ssh-connection-command" {
  value = "ssh -i ${local.key-name}.pem ec2-user@${aws_instance.tf-ec2.public_ip}"
}