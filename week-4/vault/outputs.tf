output "vault_bucket_name" {
  description = "S3 bucket holding the immutable evidence vault. Use as VAULT_BUCKET for verify-evidence.sh."
  value       = aws_s3_bucket.vault.id
}

output "vault_bucket_arn" {
  description = "ARN of the evidence vault bucket."
  value       = aws_s3_bucket.vault.arn
}

# Preservation attestation (AU-10 continued)
output "default_retention_mode" {
  description = "Preservation attestation: Object Lock default retention mode applied to every upload."
  value       = one(aws_s3_bucket_object_lock_configuration.vault.rule[*].default_retention[0].mode)
}

output "default_retention_days" {
  description = "Preservation attestation: how many days each upload is retained by default."
  value       = one(aws_s3_bucket_object_lock_configuration.vault.rule[*].default_retention[0].days)
}
