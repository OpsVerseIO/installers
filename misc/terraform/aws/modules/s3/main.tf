resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name 
  tags = merge(var.bucket_tags)
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket.id
  acl    = var.public_access ? "public-read" : "private"
}

resource "aws_s3_bucket_public_access_block" "public_access_policy" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls         = var.public_access ? false: true
  block_public_policy       = var.public_access ? false: true
  ignore_public_acls        = var.public_access ? false: true
  restrict_public_buckets   = var.public_access ? false: true
}
