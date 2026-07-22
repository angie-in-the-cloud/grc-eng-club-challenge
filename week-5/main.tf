terraform {
  required_version = ">= 1.6"
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    random = { source = "hashicorp/random", version = "~> 3.6" }
  }
}

provider "aws" {
  region = var.region

  # CM-6: Configuration Settings (tags)
  default_tags {
    tags = {
      Project         = var.project_name
      Environment     = var.environment
      ManagedBy       = "Terraform"
      ComplianceScope = "NIST-800-53"
      Week            = "5"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  log_bucket_name = "${var.project_name}-${var.environment}-cloudtrail-${random_id.suffix.hex}"

  # The trail's ARN is deterministic from its name, region, and account -- we
  # can reference it in the bucket policy without a dependency on the trail
  # resource itself, which avoids a bucket <-> trail circular dependency.
  trail_arn = "arn:${local.partition}:cloudtrail:${var.region}:${local.account_id}:trail/${var.trail_name}"
}

# -----------------------------------------------------------------------------
# Evidence bucket: private, encrypted, public access blocked. Same pattern as
# week 1's log bucket, reused here because it's the same control (SC-28, AC-3).
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = local.log_bucket_name
}

# SC-28: Protection of Information at Rest
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# AC-3: Access Enforcement
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

# -----------------------------------------------------------------------------
# Bucket policy. This is the snag: CloudTrail writes to the bucket as a
# service, and current AWS requires the aws:SourceArn condition scoped to this
# specific trail on BOTH statements, or the trail fails to create / refuses to
# write. https://docs.aws.amazon.com/awscloudtrail/latest/userguide/create-s3-bucket-policy-for-cloudtrail.html
# -----------------------------------------------------------------------------

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs.arn]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_logs.arn}/AWSLogs/${local.account_id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  policy = data.aws_iam_policy_document.cloudtrail_bucket_policy.json
}

# -----------------------------------------------------------------------------
# The trail. Multi-region, log file validation on. That validation flag is
# the AU-10 control: CloudTrail signs an hourly digest file so tampering with
# a log record after the fact is provable.
# Maps: AU-2 (event logging), AU-12 (audit record generation), AU-10
# (non-repudiation of the audit trail itself).
# -----------------------------------------------------------------------------

resource "aws_cloudtrail" "this" {
  name                          = var.trail_name
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  is_multi_region_trail         = true
  include_global_service_events = true
  enable_log_file_validation    = true # AU-10: non-repudiation

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}

# -----------------------------------------------------------------------------
# Security Hub, subscribed to the NIST 800-53 Rev 5 standard. Enabling the
# account and subscribing the standard are two separate resources.
# Maps: RA-5 (vulnerability/configuration scanning), SI-4 (system monitoring).
# -----------------------------------------------------------------------------

resource "aws_securityhub_account" "this" {
  count = var.enable_security_hub ? 1 : 0

  # Explicit false so Terraform doesn't try to replace an already-enabled
  # account just to flip this attribute -- and so we don't silently pull in
  # AWS's default standards (CIS, Foundational Security Best Practices) on
  # top of the NIST 800-53 standard we're subscribing below.
  enable_default_standards = false
}

resource "aws_securityhub_standards_subscription" "nist_800_53" {
  count         = var.enable_security_hub ? 1 : 0
  standards_arn = "arn:${local.partition}:securityhub:${var.region}::standards/nist-800-53/v/5.0.0"

  depends_on = [aws_securityhub_account.this]
}
