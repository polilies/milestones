terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>4.0"
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

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_default_vpc" "default" {
}

data "template_file" "temp" {
  template = file("${path.module}/hostdata.tpl")
}

resource "github_repository" "bookstore" {
  name        = "bookstore_project"
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

resource "github_repository_file" "create" {
  for_each            = toset(var.paths)
  content             = file("${var.basepath}/${each.value}")
  file                = each.value
  repository          = github_repository.bookstore.name
  overwrite_on_create = true
  branch              = "main"
}

data "aws_ami" "tf_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10-hvm*"]
  }
}

locals {
  instance-type       = "t2.micro"
  key-name            = "nvirginia"
  secgr-dynamic-ports = [22, 80]
  user                = "poli"
}

resource "aws_security_group" "book-sec-gr" {
  name        = "${local.user}-api-sec-gr"
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

resource "aws_instance" "tf-ec2" {
  ami                    = data.aws_ami.tf_ami.id
  instance_type          = local.instance-type
  key_name               = local.key-name
  vpc_security_group_ids = [aws_security_group.book-sec-gr.id]
  tags = {
    Name = "bookstore-instance"
  }
  user_data = data.template_file.temp.rendered
}
