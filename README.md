# GRC Pipeline Challenge

My work for the GRC Pipeline Challenge. Each week builds one brick of a compliance-as-code pipeline: express a security control as infrastructure, then emit machine-readable proof of it.

## Weeks

- **[Week 1: Compliant S3 Bucket (NIST 800-53)](week-1/)** - Terraform that enforces **SC-28, AC-3, CM-6, and AU-3** on S3 buckets and emits the proof as `evidence/plan.json`.
- **[Week 2: Executable Compliance Policies (NIST 800-53)](week-2/)** - Rego/OPA policies that read a Terraform plan and deny **SC-28, AC-3, and CM-6** violations, proven with `opa test` and gated against the real week 1 plan with Conftest.
- **[Week 3: Build the Gate (CI Policy Enforcement)](week-3/)** - GitHub Actions workflow that runs the week 2 policies with Conftest on every pull request to `main`, fails the build on any violation, uploads the results as an evidence artifact, and blocks non-compliant merges via branch protection.
- **[Week 4: Sign the Evidence (Chain of Custody)](week-4/)** - Extends the gate to sign every run's evidence with **Cosign keyless** (Sigstore OIDC), writing a SHA-256 sidecar and a signature bundle, plus a `verify-evidence.sh` that proves **authenticity, integrity, and timeliness**. A one-byte tamper fails verification while the real bundle reports `CHAIN INTACT`.
- - **[Week 5: Turn On the Cameras (Native Cloud Monitoring)](week-5/)** - Multi-region CloudTrail with `enable_log_file_validation = true` and Security Hub subscribed to the NIST 800-53 Rev 5 standard, mapping **AU-2, AU-12, AU-10, RA-5, and SI-4**. Findings are captured as `evidence/`, signed and verified `CHAIN INTACT` with the week 4 pipeline, then torn down same-day to keep cost in pennies.

_More weeks added as the challenge progresses._

#GRCEngClubChallenge
