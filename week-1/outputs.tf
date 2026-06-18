output "bucket_name" {
  description = "Primary bucket name."
  value       = aws_s3_bucket.primary.id
}

output "bucket_arn" {
  description = "Primary bucket ARN."
  value       = aws_s3_bucket.primary.arn
}

output "log_bucket_name" {
  description = "Log bucket name."
  value       = aws_s3_bucket.log.id
}

# SC-28: Protection of Information at Rest (attestation)
output "encryption_algorithm" {
  description = "SC-28 attestation: default server-side encryption algorithm on the primary bucket."
  value       = one(aws_s3_bucket_server_side_encryption_configuration.primary.rule[*].apply_server_side_encryption_by_default[0].sse_algorithm)
}
