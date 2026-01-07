# Changes to these locals are easy to break something. Ensure you know what you are doing (see each comment).

locals {
  namespace         = "jayson-next-gen"
  n_tidb            = 2
  n_tikv            = 3
  n_tiflash_write   = 2
  n_tiflash_compute = 2

  # image is region-local. If you changed region, please also change image.
  # https://rockylinux.org/download
  region   = "us-west-2"
  image    = "ami-0fadb4bc4d6071e9e" # Rocky-9-EC2-Base-9.6-20250531.0.x86_64
  username = "rocky"

  # If you want to change instance type, ensure that GP3 EBS is available in the instance type.
  # https://aws.amazon.com/ec2/instance-types/
  # 16c, 64GB
  tidb_instance            = "m7a.4xlarge"
  tikv_instance            = "m7a.4xlarge"
  tiflash_write_instance   = "m7a.4xlarge"
  # 32c, 128GB
  tiflash_compute_instance = "m7a.8xlarge"
  # 16c, 32GB
  center_instance = "c6a.4xlarge"
  # 4c, 8GB
  pd_instance = "c6a.xlarge"

  # The IOPS and throughput settings are also related to the EC2 instance type.
  # https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ebs-optimized.html
  tidb_volume_size            = 20
  tikv_volume_size            = 1000
  tiflash_write_volume_size   = 100
  tiflash_compute_volume_size = 500
  center_volume_size          = 100
  pd_volume_size              = 20

  master_ssh_key         = "./master_key"
  master_ssh_public      = "./master_key.pub"
  alternative_ssh_public = "~/.ssh/id_rsa.pub"
}
