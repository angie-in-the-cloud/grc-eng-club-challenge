# Angeline Williams: A GRC Engineering Pipeline, Built in Public

## What this is

I built an end-to-end pipeline that takes a piece of cloud infrastructure from "it works" to "it is audit-defensible," and proves every claimed control along the way with evidence a machine wrote, not a screenshot. 

Six weeks, six bricks: write the control as code, prove it holds, gate it in CI, sign the evidence so nobody can quietly edit it later, watch the account itself with native cloud tooling, and map the whole thing into a format an auditor's tools can verify.

## The pipeline

- **Week 1 - Compliant infrastructure as code.** Terraform enforcing SC-28 (encryption at rest), AC-3 (no public access), CM-6 (required tags), and AU-3 (access logging) on S3, emitting the plan as evidence.
- **Week 2 - Policy as code.** Rego/OPA policies that read that plan and deny SC-28/AC-3/CM-6 violations automatically, proven with `opa test` and gated against the real week 1 plan with Conftest.
- **Week 3 - A CI gate.** A GitHub Actions workflow that runs those policies on every pull request to `main` and blocks a non-compliant merge before a human ever has to notice.
- **Week 4 - Signed, tamper-evident evidence.** Every gate run bundles its evidence, hashes it, and signs it keyless with Cosign (Sigstore OIDC) - no private key to leak or rotate. A one-byte tamper fails verification; the real bundle reports `CHAIN INTACT`.
- **Week 5 - Native cloud monitoring.** CloudTrail (multi-region, log file validation on) and Security Hub (subscribed to the NIST 800-53 Rev 5 standard) turned on, findings captured and signed the same way, then torn down same-day to keep cost in pennies.
- **Week 6 - An OSCAL control mapping.** A component definition and profile an assessor's tooling can traverse: control ID to implementation to evidence link to a live, signed, independently verifiable bundle.

## Proof

- **Repo:** https://github.com/angie-in-the-cloud/grc-eng-club-challenge
- **Green PR:** https://github.com/angie-in-the-cloud/grc-eng-club-challenge/pull/1 - compliant plan, `grc-gate` passed, merge allowed
- **Red PR:** https://github.com/angie-in-the-cloud/grc-eng-club-challenge/pull/2 - encryption removed, `grc-gate` failed, merge blocked
- **Policy tests passing:** `opa test policies/ -v` - see `week-2/screenshots/pass.png`
- **Evidence verification:** `CHAIN INTACT`, all four properties (authenticity, integrity, timeliness, preservation) - see `week-4/vault/screenshots/vault-chain-intact.png`
- **OSCAL validation:** `VALID` on both the component definition and the profile - see `week-6/trestle-validate.png`

## What I would do next

With more time, I'd fold the vault upload directly into the `grc-gate` workflow itself, so every signed bundle lands in the Object Lock vault automatically instead of a manual `aws s3 cp` step. The preservation property should hold for every run, not just the one I demonstrated by hand. I'd also split evidence per control instead of one shared bundle covering all four, so a future failure in a single control doesn't force re-verifying everything else along with it.

## What I learned

A SHA-256 sidecar only proves a file hasn't *accidentally* changed since the fingerprint was taken - but someone who tampers with the file could just as easily regenerate a new matching hash to go with it. What actually stops that is the signature, because it's tied to a short-lived certificate issued at signing time, encoding *who* signed and *when*, logged permanently in a public transparency log nobody can quietly edit afterward. The hash catches corruption; the signature is what catches a forgery.

--
