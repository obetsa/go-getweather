# Input variable definitions

variable "bucket_name" {
  description = "Name of the s3 bucket"
  type        = string
}

variable "tags" {
  description = "Tags to set on the bucket."
  type        = map(string)
  default     = {}
}