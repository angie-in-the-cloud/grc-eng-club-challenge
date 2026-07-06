# METADATA
# title: AC-3 - Access Enforcement (AWS S3 public access block)
# description: Every aws_s3_bucket must have a public access block with all four flags true.
# custom:
#   control_id: AC-3
#   framework: nist-800-53
#   severity: critical
#   remediation: Add aws_s3_bucket_public_access_block referencing the bucket, all four flags true.
package compliance.ac3_aws

import rego.v1

config := input.configuration.root_module.resources

planned := input.planned_values.root_module.resources

# Deny a bucket that lacks a public access block with all four flags true.
deny contains msg if {
	some bucket in config
	bucket.type == "aws_s3_bucket"
	not has_compliant_pab(bucket.name)
	msg := sprintf("AC-3: aws_s3_bucket.%s has no public access block with all four flags true. Remediation: add an aws_s3_bucket_public_access_block referencing the bucket with block_public_acls, block_public_policy, ignore_public_acls, and restrict_public_buckets all true.", [bucket.name])
}

# Find a public access block that references this bucket (config side), then
# confirm its planned values have all four flags set to true.
has_compliant_pab(name) if {
	some pab in config
	pab.type == "aws_s3_bucket_public_access_block"
	pab.expressions.bucket.references[_] == sprintf("aws_s3_bucket.%s.id", [name])

	some pv in planned
	pv.address == sprintf("aws_s3_bucket_public_access_block.%s", [pab.name])
	pv.values.block_public_acls == true
	pv.values.block_public_policy == true
	pv.values.ignore_public_acls == true
	pv.values.restrict_public_buckets == true
}
