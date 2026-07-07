# GRC Pipeline Challenge

My work for the GRC Pipeline Challenge. Each week builds one brick of a compliance-as-code pipeline: express a security control as infrastructure, then emit machine-readable proof of it.

## Weeks

- **[Week 1: Compliant S3 Bucket (NIST 800-53)](week-1/)** - Terraform that enforces **SC-28, AC-3, CM-6, and AU-3** on S3 buckets and emits the proof as `evidence/plan.json`.
- **[Week 2: Executable Compliance Policies (NIST 800-53)](week-2/)** - Rego/OPA policies that read a Terraform plan and deny **SC-28, AC-3, and CM-6** violations, proven with `opa test` and gated against the real week 1 plan with Conftest.

_More weeks added as the challenge progresses._

#GRCEngClubChallenge
