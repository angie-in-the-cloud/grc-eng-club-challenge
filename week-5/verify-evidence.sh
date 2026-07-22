#!/usr/bin/env bash
# verify-evidence.sh <bundle.tar.gz>
# Proves an evidence bundle is intact and authentic. Each check exits non-zero
# on failure; prints CHAIN INTACT only when all of them pass.
set -euo pipefail

BUNDLE="${1:?usage: verify-evidence.sh <bundle.tar.gz>}"
SIDECAR="${BUNDLE}.sha256"
SIG_BUNDLE="${SIG_BUNDLE:-evidence.sig.bundle}"

# The identity the signature must carry. Defaults target this repo's gate
# workflow; override via env vars to verify a different run.
OIDC_ISSUER="${OIDC_ISSUER:-https://token.actions.githubusercontent.com}"
CERT_IDENTITY_REGEXP="${CERT_IDENTITY_REGEXP:-^https://github.com/angie-in-the-cloud/grc-eng-club-challenge/\.github/workflows/grc-gate\.yml@.*}"

fail() { echo "FAIL: $*" >&2; exit 1; }

# Pick a SHA-256 tool (Linux: sha256sum, macOS / Git Bash: shasum -a 256).
if command -v sha256sum >/dev/null 2>&1; then
  sha256_of() { sha256sum "$1" | awk '{print $1}'; }
elif command -v shasum >/dev/null 2>&1; then
  sha256_of() { shasum -a 256 "$1" | awk '{print $1}'; }
else
  fail "no sha256 tool found (need sha256sum or shasum)"
fi

# 1. INTEGRITY -----------------------------------------------------------------
#    Recompute the bundle's SHA-256 and compare it to the sidecar written when
#    the bundle was created. A single changed byte breaks this.
[ -f "$BUNDLE" ]  || fail "bundle not found: $BUNDLE"
[ -f "$SIDECAR" ] || fail "sidecar not found: $SIDECAR"
expected="$(tr -d '[:space:]' < "$SIDECAR")"
actual="$(sha256_of "$BUNDLE")"
[ "$expected" = "$actual" ] || fail "integrity: hash mismatch
  expected (sidecar): $expected
  actual   (bundle):  $actual"
echo "OK  integrity   : sha-256 matches sidecar ($actual)"

# 2. AUTHENTICITY + TIMELINESS -------------------------------------------------
#    cosign verify-blob checks the signature against the certificate and the
#    transparency-log entry (which carries the signed timestamp), pinning the
#    OIDC issuer to GitHub Actions and the identity to this repo's workflow.
command -v cosign >/dev/null 2>&1 || fail "cosign not installed"
[ -f "$SIG_BUNDLE" ] || fail "signature bundle not found: $SIG_BUNDLE"
cosign verify-blob \
  --bundle "$SIG_BUNDLE" \
  --certificate-oidc-issuer "$OIDC_ISSUER" \
  --certificate-identity-regexp "$CERT_IDENTITY_REGEXP" \
  "$BUNDLE" \
  || fail "authenticity: cosign verify-blob failed"
echo "OK  authenticity: cosign verified signature, certificate, and tlog entry"

# 3. PRESERVATION (stretch) ----------------------------------------------------
#    If the bundle was uploaded to an S3 Object Lock vault, confirm the
#    retention date is still in the future. Set VAULT_BUCKET and VAULT_KEY.
if [ -n "${VAULT_BUCKET:-}" ] && [ -n "${VAULT_KEY:-}" ]; then
  retain="$(aws s3api get-object-retention --bucket "$VAULT_BUCKET" --key "$VAULT_KEY" \
    --query 'Retention.RetainUntilDate' --output text)"
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  # ISO-8601 UTC strings compare lexicographically.
  [[ "$retain" > "$now" ]] || fail "preservation: object-lock retention expired ($retain)"
  echo "OK  preservation: object-lock retained until $retain"
else
  echo "--  preservation: skipped (set VAULT_BUCKET and VAULT_KEY to check)"
fi

echo "CHAIN INTACT"
