locals {
  common_tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.web_instance_type
  subnet_id                   = aws_subnet.public.id
  private_ip                  = "10.0.0.5"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.web.name

  root_block_device {
    volume_type = "gp3"
    volume_size = 12
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-web"
    Role = "web"
  })
}

resource "aws_eip" "web" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-web-eip"
  }
}

resource "aws_eip_association" "web" {
  instance_id   = aws_instance.web.id
  allocation_id = aws_eip.web.id
}

resource "aws_instance" "controller" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.controller_instance_type
  subnet_id                   = aws_subnet.private.id
  private_ip                  = "10.0.0.135"
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.controller.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.controller.name

  user_data = <<-EOT
    #!/bin/bash
    set -eux
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -y
    apt-get install -y ansible-core git curl unzip docker.io docker-compose-v2 awscli
    systemctl enable --now docker
    usermod -aG docker ubuntu
  EOT

  root_block_device {
    volume_type = "gp3"
    volume_size = 12
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-controller"
    Role = "ansible-controller"
  })
}

resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.monitoring_instance_type
  subnet_id                   = aws_subnet.private.id
  private_ip                  = "10.0.0.136"
  associate_public_ip_address = false
  vpc_security_group_ids      = [aws_security_group.monitoring.id]
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.monitoring.name

  root_block_device {
    volume_type = "gp3"
    volume_size = 16
    encrypted   = true
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-monitoring"
    Role = "monitoring"
  })
}
