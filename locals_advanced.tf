# Changes to these locals are easy to break something. Ensure you know what you are doing (see each comment).

locals {
  # image is region-local. If you changed region, please also change image.
  # AMIs of each region (Ubuntu 22.04 + OMZ + KernelTunes):
  # us-east-1	ami-0e2732470fc684140
  # us-east-2	ami-05cda54fbc39e2381
  # us-west-1	ami-0575bfdeb6f59b5d8
  # us-west-2	ami-003e5556ddc999e13
  region = "us-west-2"
  image  = "ami-003e5556ddc999e13"

  # If you want to change instance type, ensure that GP3 EBS is available in the instance type.
  tidb_instance    = "c5.4xlarge"
  tikv_instance    = "m5.4xlarge"
  pd_instance      = "m5.2xlarge"
  tiflash_instance = "r5.2xlarge"
  center_instance  = "c5.2xlarge"

  tikv_volume_size       = 4096
  tiflash_cn_volume_size = 400
  tiflash_wn_volume_size = 4096

  tikv_volume_throughput = 593
  tiflash_volume_throughput = 288

  master_ssh_key         = "./master_key"
  master_ssh_public      = "./master_key.pub"
  alternative_ssh_public = "~/.ssh/id_rsa.pub"
}
