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
      Week            = "4-vault"
    }
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  vault_bucket_name = "${var.project_name}-${var.environment}-evidence-vault-${random_id.suffix.hex}"
}

# -----------------------------------------------------------------------------
# The vault. Object Lock can ONLY be enabled at bucket creation time -- it
# cannot be turned on for an existing bucket. Versioning is a hard prerequisite
# for Object Lock: AWS will reject the bucket otherwise.
# -----------------------------------------------------------------------------

resource "aws_s3_bucket" "vault" {
  bucket              = local.vault_bucket_name
  object_lock_enabled = true
}

resource "aws_s3_bucket_versioning" "vault" {
  bucket = aws_s3_bucket.vault.id

  versioning_configuration {
    status = "Enabled"
  }
}

# SC-28: Protection of Information at Rest
resource "aws_s3_bucket_server_side_encryption_configuration" "vault" {
  bucket = aws_s3_bucket.vault.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# AC-3: Access Enforcement
resource "aws_s3_bucket_public_access_block" "vault" {
  bucket = aws_s3_bucket.vault.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Default retention rule: every object uploaded gets COMPLIANCE-mode retention
# automatically, so a person cannot forget to set it (or quietly weaken it)
# on a per-upload basis. COMPLIANCE mode means nobody -- not even the account
# root user -- can shorten or delete the retention before it expires. This is
# the AU-10 / preservation property: the evidence genuinely cannot be
# destroyed or overwritten early, by anyone, once it lands here.
resource "aws_s3_bucket_object_lock_configuration" "vault" {
  bucket = aws_s3_bucket.vault.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = var.retention_days
    }
  }

  depends_on = [aws_s3_bucket_versioning.vault]
}
