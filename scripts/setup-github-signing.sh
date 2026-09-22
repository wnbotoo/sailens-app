#!/usr/bin/env bash
set -euo pipefail

umask 077

REPOSITORY="${SAILENS_GITHUB_REPOSITORY:-wnbotoo/sailens-app}"
SIGNING_DIR="${SAILENS_SIGNING_DIR:-$HOME/.sailens/signing}"
KEYSTORE="${SAILENS_APP_SIGNING_KEYSTORE_PATH:-$SIGNING_DIR/sailens-app-signing.p12}"
KEY_ALIAS="${SAILENS_APP_SIGNING_KEY_ALIAS_VALUE:-sailens-app}"

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: required command not found: $1" >&2
    exit 1
  fi
}

read_secret_twice() {
  local prompt="$1"
  local confirm_prompt="$2"
  local value confirm

  read -r -s -p "$prompt" value
  echo >&2
  read -r -s -p "$confirm_prompt" confirm
  echo >&2

  if [[ "$value" != "$confirm" ]]; then
    echo "error: values do not match." >&2
    return 1
  fi
  if (( ${#value} < 12 )); then
    echo "error: use at least 12 characters for a long-lived signing password." >&2
    return 1
  fi

  printf '%s' "$value"
}

require_command keytool
require_command python3
require_command gh

if ! gh auth status --hostname github.com >/dev/null 2>&1; then
  echo "error: GitHub CLI is not authenticated. Run 'gh auth login' first." >&2
  exit 1
fi

mkdir -p "$SIGNING_DIR"
chmod 700 "$SIGNING_DIR"

echo "Repository: $REPOSITORY"
echo "Keystore:   $KEYSTORE"
echo "Type:       PKCS12"
echo "Alias:      $KEY_ALIAS"
echo

store_password="$(
  read_secret_twice     "Signing password: "     "Confirm signing password: "
)"

# Android recommends using the same password for the keystore and private key.
key_password="$store_password"
export SAILENS_KEYTOOL_STORE_PASSWORD="$store_password"

if [[ -e "$KEYSTORE" ]]; then
  read -r -p "PKCS12 keystore already exists. Reuse it without overwriting? [y/N] " answer
  case "$answer" in
    y|Y|yes|YES)
      keytool -list         -keystore "$KEYSTORE"         -storetype PKCS12         -alias "$KEY_ALIAS"         -storepass:env SAILENS_KEYTOOL_STORE_PASSWORD >/dev/null
      ;;
    *)
      echo "error: refusing to overwrite existing keystore: $KEYSTORE" >&2
      exit 1
      ;;
  esac
else
  keytool -genkeypair -noprompt     -keystore "$KEYSTORE"     -storetype PKCS12     -alias "$KEY_ALIAS"     -keyalg RSA     -keysize 4096     -validity 10000     -dname "CN=Sailens Android, O=Sailens"     -storepass:env SAILENS_KEYTOOL_STORE_PASSWORD
  chmod 600 "$KEYSTORE"
fi

certificate_sha256="$(
  keytool -exportcert     -keystore "$KEYSTORE"     -storetype PKCS12     -alias "$KEY_ALIAS"     -storepass:env SAILENS_KEYTOOL_STORE_PASSWORD |
    python3 -c 'import hashlib, sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())'
)"

echo
echo "App-signing certificate SHA-256:"
echo "$certificate_sha256"
echo
echo "Before the first public release, make an offline backup of:"
echo "  $KEYSTORE"
echo
read -r -p "Upload the four signing values to GitHub Actions secrets for $REPOSITORY? [y/N] " answer
case "$answer" in
  y|Y|yes|YES) ;;
  *)
    echo "Secrets were not changed."
    exit 0
    ;;
esac

python3 -c 'import base64, pathlib, sys; sys.stdout.write(base64.b64encode(pathlib.Path(sys.argv[1]).read_bytes()).decode())' "$KEYSTORE" |
  gh secret set SAILENS_APP_SIGNING_KEYSTORE_BASE64 --repo "$REPOSITORY"

printf '%s' "$store_password" |
  gh secret set SAILENS_APP_SIGNING_STORE_PASSWORD --repo "$REPOSITORY"

printf '%s' "$KEY_ALIAS" |
  gh secret set SAILENS_APP_SIGNING_KEY_ALIAS --repo "$REPOSITORY"

printf '%s' "$key_password" |
  gh secret set SAILENS_APP_SIGNING_KEY_PASSWORD --repo "$REPOSITORY"

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
echo "Signing setup complete."
echo "GitHub reports all four required Actions secret names."
echo "Keystore type: PKCS12"
echo "Certificate SHA-256: $certificate_sha256"
echo
echo "Do not create a release tag until the keystore has an offline backup and the physical-device release gate is complete."
