variable "region" {
  type        = string
  description = "AWS region to deploy into. CloudTrail is multi-region regardless, but resources still need a home region."
  default     = "us-east-1"
}

variable "project_name" {
  type        = string
  description = "Short project identifier. Becomes part of bucket names and the Project tag."
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,20}$", var.project_name))
    error_message = "project_name must be 3-21 lowercase alphanumerics or hyphens, starting with a letter."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment. Drives the Environment tag."
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "trail_name" {
  type        = string
  description = "Name of the CloudTrail trail."
  default     = "grc-challenge-trail"
}

variable "enable_security_hub" {
  type        = bool
  description = "Set to false if Security Hub is already enabled in this account (import it instead -- see README common snags)."
  default     = true
}
