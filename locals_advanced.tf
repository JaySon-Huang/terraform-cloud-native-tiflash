# Changes to these locals are easy to break something. Ensure you know what you are doing (see each comment).

locals {
  # image is region-local. If you changed region, please also change image.
  # AMIs of each region (Ubuntu 22.04 + OMZ + KernelTunes):
  # us-east-1	ami-0e2732470fc684140
  # us-east-2	ami-05cda54fbc39e2381
  # us-west-1	ami-0575bfdeb6f59b5d8
  # us-west-2	ami-003e5556ddc999e13
  region = "us-west-2"
  # https://rockylinux.org/download
  image = "ami-03be04a3da3a40226" # Rocky-9-EC2-Base-9.5-20241118.0.aarch64

  # If you want to change instance type, ensure that GP3 EBS is available in the instance type.
  # center_instance  = "m6g.2xlarge"
  center_instance  = "m6g.medium"

  master_ssh_key         = "./master_key"
  master_ssh_public      = "./master_key.pub"
  alternative_ssh_public = "~/.ssh/id_rsa.pub"
}
