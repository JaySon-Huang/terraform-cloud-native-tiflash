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
  pd_private_ip               = "172.31.8.1"
  tidb_private_ips            = [for i in range(local.n_tidb) : "172.31.7.${i + 1}"]
  tikv_private_ips            = [for i in range(local.n_tikv) : "172.31.6.${i + 1}"]
  tiflash_write_private_ips   = [for i in range(local.n_tiflash_write) : "172.31.9.${i + 1}"]
  tiflash_compute_private_ips = [for i in range(local.n_tiflash_compute) : "172.31.10.${i + 1}"]
  center_private_ip           = "172.31.1.1"
}

resource "aws_instance" "tidb" {
  count = local.n_tidb

  ami                         = local.image
  instance_type               = local.tidb_instance
  key_name                    = aws_key_pair.master_key.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  private_ip                  = local.tidb_private_ips[count.index]

  root_block_device {
    volume_size           = local.tidb_volume.size
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = local.tidb_volume.iops
    throughput            = local.tidb_volume.throughput
  }

  tags = {
    Name = "${local.namespace}-tidb-${count.index}"
  }

  user_data_base64 = data.cloudinit_config.common_server.rendered
}

resource "aws_instance" "pd" {
  ami                         = local.image
  instance_type               = local.pd_instance
  key_name                    = aws_key_pair.master_key.id
  vpc_security_group_ids      = [aws_security_group.ssh.id, aws_security_group.etcd.id, aws_security_group.grafana.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  private_ip                  = local.pd_private_ip

  root_block_device {
    volume_size           = local.pd_volume.size
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = local.pd_volume.iops
    throughput            = local.pd_volume.throughput
  }

  tags = {
    Name = "${local.namespace}-pd-1"
  }

  user_data_base64 = data.cloudinit_config.common_server.rendered
}

resource "aws_instance" "tikv" {
  count = local.n_tikv

  ami                         = local.image
  instance_type               = local.tikv_instance
  key_name                    = aws_key_pair.master_key.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  private_ip                  = local.tikv_private_ips[count.index]

  root_block_device {
    volume_size           = local.tikv_volume.size
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = local.tikv_volume.iops
    throughput            = local.tikv_volume.throughput
  }

  tags = {
    Name = "${local.namespace}-tikv-${count.index}"
  }

  user_data_base64 = data.cloudinit_config.common_server.rendered
}

resource "aws_instance" "tiflash_write" {
  count = local.n_tiflash_write

  ami                         = local.image
  instance_type               = local.tiflash_write_instance
  key_name                    = aws_key_pair.master_key.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  private_ip                  = local.tiflash_write_private_ips[count.index]

  root_block_device {
    volume_size           = local.tiflash_write_volume.size
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = local.tiflash_write_volume.iops
    throughput            = local.tiflash_write_volume.throughput
  }

  tags = {
    Name = "${local.namespace}-tiflash-write-${count.index}"
  }

  user_data_base64 = data.cloudinit_config.common_server.rendered
}

resource "aws_instance" "tiflash_compute" {
  count = local.n_tiflash_compute

  ami                         = local.image
  instance_type               = local.tiflash_compute_instance
  key_name                    = aws_key_pair.master_key.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  private_ip                  = local.tiflash_compute_private_ips[count.index]

  root_block_device {
    volume_size           = local.tiflash_compute_volume.size
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = local.tiflash_compute_volume.iops
    throughput            = local.tiflash_compute_volume.throughput
  }

  tags = {
    Name = "${local.namespace}-tiflash-compute-${count.index}"
  }

  user_data_base64 = data.cloudinit_config.common_server.rendered
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
    volume_size           = local.center_volume.size
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = local.center_volume.iops
    throughput            = local.center_volume.throughput
  }

  tags = {
    Name = "${local.namespace}-center"
  }

  user_data_base64 = data.cloudinit_config.center_server.rendered
}

# locals {
#   all_instance_ips = merge(
#     { for idx, ip in aws_instance.tidb[*].public_ip : "tidb-${idx}" => ip },
#     { for idx, ip in aws_instance.pd[*].public_ip : "pd-${idx}" => ip },
#     { for idx, ip in aws_instance.tikv[*].public_ip : "tikv-${idx}" => ip },
#     { for idx, ip in aws_instance.tiflash_write[*].public_ip : "tiflash-write-${idx}" => ip },
#     { for idx, ip in aws_instance.tiflash_compute[*].public_ip : "tiflash-compute-${idx}" => ip },
#     { for idx, ip in aws_instance.center[*].public_ip : "center-${idx}" => ip },
#   )
# }

# resource "null_resource" "deploy_rocky_ssh_keys" {
#   for_each = local.all_instance_ips

#   triggers = {
#     master_key_hash = filebase64sha256(local.master_ssh_key)
#     master_key_pub  = file(local.master_ssh_public)
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "sudo mkdir -p /home/rocky/.ssh",
#       "set -x",

#       "cat > /tmp/id_rsa << 'EOF'",
#       file("${local.master_ssh_key}"),
#       "EOF",
#       "sudo mv /tmp/id_rsa /home/rocky/.ssh/id_rsa",
#       "sudo chmod 600 /home/rocky/.ssh/id_rsa",

#       "cat > /tmp/id_rsa.pub << 'EOF'",
#       file("${local.master_ssh_public}"),
#       "EOF",
#       "sudo mv /tmp/id_rsa.pub /home/rocky/.ssh/id_rsa.pub",
#       "sudo chmod 644 /home/rocky/.ssh/id_rsa.pub",

#       "sudo chown -R rocky:rocky /home/rocky/.ssh",

#       "sudo mkdir -p /home/rocky/.ssh",
#       "sudo cp /home/rocky/.ssh/id_rsa.pub /home/rocky/.ssh/authorized_keys 2>/dev/null || true",
#       "sudo chmod 600 /home/rocky/.ssh/authorized_keys",
#       "sudo chown rocky:rocky /home/rocky/.ssh/authorized_keys",

#       "echo '✅ SSH 密钥已部署到 ${each.key} (${each.value})'"
#     ]

#     connection {
#       type        = "ssh"
#       host        = each.value 
#       user        = "rocky"     
#       private_key = file(local.master_ssh_key)
#     }
#   }

#   # 确保在所有实例创建后再运行
#   depends_on = [
#     aws_instance.tidb,
#     aws_instance.pd,
#     aws_instance.tikv,
#     aws_instance.tiflash_write,
#     aws_instance.tiflash_compute,
#     aws_instance.center,
#   ]
# }
