variable "s3_bucket_name" {
  description = "The name of the S3 bucket to store code detection results"
  type        = string
  default     = "code-detection-bedrock-results"
}

variable "identitystore_id" {
  description = "ID of the IAM Identity Center identity store"
}

variable "grafana_admin_username" {
  description = "Username (or email) of the SSO user who should be Grafana Admin"
}