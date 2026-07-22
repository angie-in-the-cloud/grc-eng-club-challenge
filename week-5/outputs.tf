output "cloudtrail_bucket_name" {
  description = "S3 bucket receiving CloudTrail logs."
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "trail_arn" {
  description = "ARN of the CloudTrail trail."
  value       = aws_cloudtrail.this.arn
}

# AU-10: Non-repudiation (attestation)
output "log_file_validation_enabled" {
  description = "AU-10 attestation: log file validation is on, so CloudTrail emits a signed digest proving the logs haven't been altered."
  value       = aws_cloudtrail.this.enable_log_file_validation
}

output "security_hub_standard_arn" {
  description = "The NIST 800-53 Rev 5 standard subscribed in Security Hub (RA-5, SI-4)."
  value       = var.enable_security_hub ? aws_securityhub_standards_subscription.nist_800_53[0].standards_arn : null
}
