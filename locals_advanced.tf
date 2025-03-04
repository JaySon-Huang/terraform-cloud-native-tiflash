# Changes to these locals are easy to break something. Ensure you know what you are doing (see each comment).

locals {
  # image is region-local. If you changed region, please also change image.
  region = "us-west-2"
  # https://cloud-images.ubuntu.com/locator/ec2/
  image = "ami-08e65f4539212dfd2" # ubuntu 22.04 aarch64

  # # If you want to change instance type, ensure that GP3 EBS is available in the instance type.
  center_instance  = "m6g.2xlarge"

  master_ssh_key         = "./master_key"
  master_ssh_public      = "./master_key.pub"
  alternative_ssh_public = "~/.ssh/id_rsa.pub"
}
