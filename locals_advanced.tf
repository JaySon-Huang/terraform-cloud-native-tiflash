# Changes to these locals are easy to break something. Ensure you know what you are doing (see each comment).

locals {
  # image is region-local. If you changed region, please also change image.
  region = "us-west-2"
  # https://rockylinux.org/download
  image = "ami-0fadb4bc4d6071e9e" # Rocky-9-EC2-Base-9.6-20250531.0.x86_64

  # If you want to change instance type, ensure that GP3 EBS is available in the instance type.
  # https://aws.amazon.com/ec2/instance-types/
  center_instance  = "m7i.2xlarge"

  master_ssh_key         = "./master_key"
  master_ssh_public      = "./master_key.pub"
  alternative_ssh_public = "~/.ssh/id_rsa.pub"
}
