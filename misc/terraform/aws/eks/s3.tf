##############
# Loki storage buckets
##############

module "s3_bucket_opsverse" {
  source = "../modules/s3"

  bucket_name = var.s3_bucket 
  bucket_tags = {
    Name        = var.s3_bucket
    Environment = "production"
  }
}

