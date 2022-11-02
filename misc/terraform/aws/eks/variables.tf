## Fill in with your network configs
variable "aws_region" {}
variable "keypair_name" {}
variable "s3_bucket" { }
variable "subnet_ids" { type = list }
variable "vpc_id" {}
variable "aws_profile" {}

