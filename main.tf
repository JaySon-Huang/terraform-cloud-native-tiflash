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
  pd_private_ip = "172.31.8.1"
  tidb_private_ips = [for i in range(local.n_tidb) : "172.31.7.${i + 1}"]
  tikv_private_ips = [for i in range(local.n_tikv) : "172.31.6.${i + 1}"]
  tiflash_write_private_ips = [for i in range(local.n_tiflash_write) : "172.31.9.${i + 1}"]
  tiflash_compute_private_ips = [for i in range(local.n_tiflash_compute) : "172.31.10.${i + 1}"]
  center_private_ip = "172.31.1.1"
}

resource "aws_instance" "center" {
  ami                         = local.image
  instance_type               = local.center_instance
  key_name                    = aws_key_pair.master_key.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  private_ip                  = local.center_private_ip

  root_block_device {
    volume_size           = 200
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
  }

  tags = {
    Name = "${local.namespace}-center"
  }

  user_data_base64 = data.cloudinit_config.center_server.rendered
}
