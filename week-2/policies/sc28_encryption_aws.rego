# METADATA
# title: SC-28 - Encryption at Rest (AWS S3)
# description: Every aws_s3_bucket must have a matching server-side encryption configuration.
# custom:
#   control_id: SC-28
#   framework: nist-800-53
#   severity: high
#   remediation: Add aws_s3_bucket_server_side_encryption_configuration referencing the bucket.
package compliance.sc28_aws

import rego.v1

resources := input.configuration.root_module.resources

# Deny a bucket that has no encryption configuration pointing at it.
deny contains msg if {
	some bucket in resources
	bucket.type == "aws_s3_bucket"
	not has_encryption(bucket.name)
	msg := sprintf("SC-28: aws_s3_bucket.%s has no server-side encryption configuration. Remediation: add an aws_s3_bucket_server_side_encryption_configuration referencing the bucket.", [bucket.name])
}

# We match by reference, not by name: the bucket's final name is unknown at plan
# time, so we look for an encryption resource whose bucket argument references
# this bucket's address (e.g. "aws_s3_bucket.primary.id").
has_encryption(name) if {
	some r in resources
	r.type == "aws_s3_bucket_server_side_encryption_configuration"
	r.expressions.bucket.references[_] == sprintf("aws_s3_bucket.%s.id", [name])
}
