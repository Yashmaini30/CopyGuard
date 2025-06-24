variable "s3_bucket_name" {
  description = "The name of the S3 bucket to store code detection results"
  type        = string
  default     = "code-detection-bedrock-results"
}