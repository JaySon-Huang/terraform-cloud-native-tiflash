terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.53.0"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = local.region
  default_tags {
    tags = {
      Usage = local.namespace
    }
  }
}

resource "random_id" "id" {
  byte_length = 4
}

resource "aws_key_pair" "master_key" {
  public_key = file(local.master_ssh_public)
}

locals {
  provisioner_add_alternative_ssh_public = [
    "echo '${file(local.alternative_ssh_public)}' | tee -a ~/.ssh/authorized_keys",
  ]
}

resource "aws_instance" "center" {
  ami                         = local.image
  instance_type               = local.center_instance
  key_name                    = aws_key_pair.master_key.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  private_ip                  = "172.31.1.1"

  root_block_device {
    # The IOPS and throughput settings are also related to the EC2 instance type.
    # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-optimized.html
    volume_size           = 100
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = 16000
    throughput            = 625
  }

  tags = {
    Name = "${local.namespace}-center"
  }

  connection {
    type        = "ssh"
    user        = local.username
    private_key = file(local.master_ssh_key)
    host        = self.public_ip
  }

  provisioner "remote-exec" {
    inline = local.provisioner_add_alternative_ssh_public
  }
  provisioner "remote-exec" {
    script = "./files/bootstrap_all.sh"
  }

  # add keys to access other hosts
  provisioner "file" {
    source      = local.master_ssh_key
    destination = "/home/${local.username}/.ssh/id_rsa"
  }
  provisioner "file" {
    source      = local.master_ssh_public
    destination = "/home/${local.username}/.ssh/id_rsa.pub"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod 400 ~/.ssh/id_rsa",
    ]
  }

  provisioner "remote-exec" {
    script = "./files/bootstrap_center.sh"
  }
}
