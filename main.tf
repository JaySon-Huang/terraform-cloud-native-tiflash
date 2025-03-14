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

resource "aws_instance" "tidb" {
  count = local.n_tidb

  ami                         = local.image
  instance_type               = local.tidb_instance
  key_name                    = aws_key_pair.master_key.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  private_ip                  = "172.31.7.${count.index + 1}"

  root_block_device {
    volume_size           = 100
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
  }

  tags = {
    Name = "${local.namespace}-tidb-${count.index}"
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
}

resource "aws_network_interface" "pd" {
  subnet_id       = aws_subnet.main.id
  private_ips     = ["172.31.8.1"]
  security_groups = [aws_security_group.ssh.id, aws_security_group.etcd.id, aws_security_group.grafana.id]
}

resource "aws_instance" "pd" {
  ami                         = local.image
  instance_type               = local.pd_instance
  key_name                    = aws_key_pair.master_key.id
  # vpc_security_group_ids      = [aws_security_group.ssh.id, aws_security_group.etcd.id, aws_security_group.grafana.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  # subnet_id                   = aws_subnet.main.id
  # private_ip                  = "172.31.8.1"

  network_interface {
    network_interface_id = aws_network_interface.pd.id
    device_index         = 0
  }

  root_block_device {
    volume_size           = 100
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
  }

  tags = {
    Name = "${local.namespace}-pd-1"
  }

  connection {
    type        = "ssh"
    user        = local.username
    private_key = file(local.master_ssh_key)
    host        = aws_eip.pd.public_ip
  }

  provisioner "remote-exec" {
    inline = local.provisioner_add_alternative_ssh_public
  }
  provisioner "remote-exec" {
    script = "./files/bootstrap_all.sh"
  }
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
  private_ip                  = "172.31.6.${count.index + 1}"

  root_block_device {
    volume_size           = 800
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = 4000
    throughput            = 288
  }

  tags = {
    Name = "${local.namespace}-tikv-${count.index}"
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
}

resource "aws_instance" "tiflash_write" {
  count = local.n_tiflash_write

  ami                         = local.image
  instance_type               = local.tiflash_instance
  key_name                    = aws_key_pair.master_key.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  private_ip                  = "172.31.9.${count.index + 1}"

  root_block_device {
    volume_size           = 600
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = 4000
    throughput            = 594
  }

  tags = {
    Name = "${local.namespace}-tiflash-write-${count.index}"
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
}

resource "aws_instance" "tiflash_compute" {
  count = local.n_tiflash_compute

  ami                         = local.image
  instance_type               = local.tiflash_instance
  key_name                    = aws_key_pair.master_key.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  subnet_id                   = aws_subnet.main.id
  associate_public_ip_address = true
  private_ip                  = "172.31.10.${count.index + 1}"

  root_block_device {
    volume_size           = 300
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = 4000
    throughput            = 288
  }

  tags = {
    Name = "${local.namespace}-tiflash-compute-${count.index}"
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
}

resource "aws_network_interface" "center" {
  subnet_id       = aws_subnet.main.id
  private_ips     = ["172.31.1.1"]
  security_groups = [aws_security_group.ssh.id]
}

resource "aws_instance" "center" {
  ami                         = local.image
  instance_type               = local.center_instance
  key_name                    = aws_key_pair.master_key.id
  # vpc_security_group_ids      = [aws_security_group.ssh.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  # subnet_id                   = aws_subnet.main.id
  # private_ip                  = "172.31.1.1"

  network_interface {
    network_interface_id = aws_network_interface.center.id
    device_index         = 0
  }

  root_block_device {
    volume_size           = 300
    delete_on_termination = true
    volume_type           = "gp3"
    iops                  = 3000
    throughput            = 125
  }

  tags = {
    Name = "${local.namespace}-center"
  }

  connection {
    type        = "ssh"
    user        = local.username
    private_key = file(local.master_ssh_key)
    host        = aws_eip.center.public_ip
  }

  provisioner "file" {
    content = templatefile("./files/haproxy.cfg.tftpl", {
      tidb_hosts = aws_instance.tidb[*].private_ip,
    })
    destination = "/home/${local.username}/haproxy.cfg"
  }

  provisioner "file" {
    content = templatefile("./files/topology.yaml.tftpl", {
      tidb_hosts = aws_instance.tidb[*].private_ip,
      tikv_hosts = aws_instance.tikv[*].private_ip,
      tiflash_write_hosts = aws_instance.tiflash_write[*].private_ip,
      tiflash_compute_hosts = aws_instance.tiflash_compute[*].private_ip,
      s3_region = local.region,
      s3_bucket = aws_s3_bucket.main.bucket,
    })
    destination = "/home/${local.username}/topology.yaml"
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
