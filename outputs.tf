output "ssh-center" {
  value = "ssh -i master_key ${local.username}@${aws_instance.center.public_ip}"
}

output "s3-bucket" {
  value = aws_s3_bucket.main.bucket
}
