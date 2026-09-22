#!/usr/bin/env bash
set -euo pipefail

umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOSITORY="${SAILENS_GITHUB_REPOSITORY:-wnbotoo/sailens-app}"
SIGNING_DIR="${SAILENS_SIGNING_DIR:-$HOME/.sailens/signing}"
KEYSTORE="${SAILENS_APP_SIGNING_KEYSTORE_PATH:-$SIGNING_DIR/sailens-app-signing.p12}"
KEY_ALIAS="${SAILENS_APP_SIGNING_KEY_ALIAS_VALUE:-sailens-app}"
EXPECTED_CERT_FILE="$ROOT/release/app-signing-certificate.sha256"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

normalize_sha256() {
  tr '[:upper:]' '[:lower:]' | tr -d ':[:space:]'
}

require_command keytool
require_command python3
require_command gh

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  echo "error: GitHub CLI is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

[[ -f "$EXPECTED_CERT_FILE" ]] || {
  echo "error: missing pinned signing identity: $EXPECTED_CERT_FILE" >&2
  exit 1
}
expected_certificate_sha256="$(normalize_sha256 < "$EXPECTED_CERT_FILE")"
[[ "$expected_certificate_sha256" =~ ^[0-9a-f]{64}$ ]] || {
  echo "error: invalid pinned signing certificate SHA-256." >&2
  exit 1
}

if [[ ! -f "$KEYSTORE" ]]; then
  echo "error: the Sailens production signing identity is already pinned, but the local PKCS12 file is missing:" >&2
  echo "  $KEYSTORE" >&2
  echo "Restore the offline backup, or set SAILENS_APP_SIGNING_KEYSTORE_PATH to the restored file." >&2
  echo "Refusing to generate a replacement signing identity." >&2
  exit 1
fi

echo "Repository: $REPOSITORY"
echo "Keystore:   $KEYSTORE"
echo "Type:       PKCS12"
echo "Alias:      $KEY_ALIAS"
echo "Pinned certificate SHA-256: $expected_certificate_sha256"
echo

read -r -s -p "Signing password: " signing_password
echo >&2
[[ ${#signing_password} -ge 12 ]] || {
  echo "error: signing password is invalid." >&2
  exit 1
}

export SAILENS_KEYTOOL_STORE_PASSWORD="$signing_password"
keytool -list \
  -keystore "$KEYSTORE" \
  -storetype PKCS12 \
  -alias "$KEY_ALIAS" \
  -storepass:env SAILENS_KEYTOOL_STORE_PASSWORD >/dev/null

certificate_sha256="$(
  keytool -exportcert \
    -keystore "$KEYSTORE" \
    -storetype PKCS12 \
    -alias "$KEY_ALIAS" \
    -storepass:env SAILENS_KEYTOOL_STORE_PASSWORD |
    python3 -c 'import hashlib, sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())'
)"
certificate_sha256="$(printf '%s' "$certificate_sha256" | normalize_sha256)"

if [[ "$certificate_sha256" != "$expected_certificate_sha256" ]]; then
  echo "error: local keystore does not match the pinned Sailens signing identity." >&2
  echo "expected: $expected_certificate_sha256" >&2
  echo "actual:   $certificate_sha256" >&2
  exit 1
fi

echo
echo "Pinned signing identity verified."
echo "Certificate SHA-256: $certificate_sha256"
echo
read -r -p "Upload this pinned signing identity to GitHub Actions secrets for $REPOSITORY? [y/N] " answer
case "$answer" in
  y|Y|yes|YES) ;;
  *)
    echo "Secrets were not changed."
    exit 0
    ;;
esac

python3 -c 'import base64, pathlib, sys; sys.stdout.write(base64.b64encode(pathlib.Path(sys.argv[1]).read_bytes()).decode())' "$KEYSTORE" |
  gh secret set SAILENS_APP_SIGNING_KEYSTORE_BASE64 --repo "$REPOSITORY"

printf '%s' "$signing_password" |
  gh secret set SAILENS_APP_SIGNING_STORE_PASSWORD --repo "$REPOSITORY"

printf '%s' "$KEY_ALIAS" |
  gh secret set SAILENS_APP_SIGNING_KEY_ALIAS --repo "$REPOSITORY"

printf '%s' "$signing_password" |
  gh secret set SAILENS_APP_SIGNING_KEY_PASSWORD --repo "$REPOSITORY"

unset signing_password
unset SAILENS_KEYTOOL_STORE_PASSWORD

expected=(
  SAILENS_APP_SIGNING_KEYSTORE_BASE64
  SAILENS_APP_SIGNING_STORE_PASSWORD
  SAILENS_APP_SIGNING_KEY_ALIAS
  SAILENS_APP_SIGNING_KEY_PASSWORD
)
secret_names="$(gh secret list --repo "$REPOSITORY" --json name --jq '.[].name')"
for name in "${expected[@]}"; do
  if ! grep -Fxq "$name" <<< "$secret_names"; then
    echo "error: GitHub did not report expected secret: $name" >&2
    exit 1
  fi
done

echo
echo "Signing secret refresh complete."
echo "GitHub reports all four required Actions secret names."
echo "Certificate SHA-256: $certificate_sha256"
echo
echo "The production signing identity remains pinned; do not generate a replacement key."
