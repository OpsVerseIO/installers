variable "bucket_name" {}
variable "bucket_tags" {
  type    = map(string)
  default = {}
}
variable "public_access" {
  default = false
}
