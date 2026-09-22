#!/usr/bin/env bash
set -euo pipefail

umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

TAG="${1:-}"
PACKAGE_NAME="com.sailens"
MAIN_ACTIVITY="com.sailens/.MainActivity"
KEYSTORE="${SAILENS_APP_SIGNING_KEYSTORE_PATH:-$HOME/.sailens/signing/sailens-app-signing.p12}"
KEY_ALIAS="${SAILENS_APP_SIGNING_KEY_ALIAS_VALUE:-sailens-app}"
EXPECTED_CERT_FILE="$ROOT/release/app-signing-certificate.sha256"

die() {
  echo "error: $*" >&2
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

normalize_sha256() {
  tr '[:upper:]' '[:lower:]' | tr -d ':[:space:]'
}

resolve_adb() {
  if [[ -n "${ADB:-}" ]]; then
    ADB_BIN="$ADB"
    return
  fi
  if command -v adb >/dev/null 2>&1; then
    ADB_BIN="$(command -v adb)"
    return
  fi
  if command -v adb.exe >/dev/null 2>&1; then
    ADB_BIN="$(command -v adb.exe)"
    return
  fi
  local root
  for root in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}"; do
    [[ -n "$root" ]] || continue
    if [[ -x "$root/platform-tools/adb" ]]; then
      ADB_BIN="$root/platform-tools/adb"
      return
    fi
    if [[ -f "$root/platform-tools/adb.exe" ]]; then
      ADB_BIN="$root/platform-tools/adb.exe"
      return
    fi
  done
  die "adb not found. Put adb/adb.exe on PATH or set ADB=/path/to/adb."
}

resolve_apksigner() {
  APKSIGNER_MODE=""
  APKSIGNER_PATH=""

  if [[ -n "${APKSIGNER:-}" ]]; then
    APKSIGNER_MODE="exec"
    APKSIGNER_PATH="$APKSIGNER"
    return
  fi
  if [[ -n "${APKSIGNER_JAR:-}" ]]; then
    APKSIGNER_MODE="jar"
    APKSIGNER_PATH="$APKSIGNER_JAR"
    return
  fi
  if command -v apksigner >/dev/null 2>&1; then
    APKSIGNER_MODE="exec"
    APKSIGNER_PATH="$(command -v apksigner)"
    return
  fi
  if command -v apksigner.bat >/dev/null 2>&1; then
    local bat jar
    bat="$(command -v apksigner.bat)"
    jar="$(dirname "$bat")/lib/apksigner.jar"
    if [[ -f "$jar" ]]; then
      APKSIGNER_MODE="jar"
      APKSIGNER_PATH="$jar"
      return
    fi
  fi

  local root jar
  for root in "${ANDROID_SDK_ROOT:-}" "${ANDROID_HOME:-}"; do
    [[ -n "$root" && -d "$root/build-tools" ]] || continue
    jar="$(find "$root/build-tools" -type f -path '*/lib/apksigner.jar' 2>/dev/null | sort -V | tail -n 1)"
    if [[ -n "$jar" ]]; then
      APKSIGNER_MODE="jar"
      APKSIGNER_PATH="$jar"
      return
    fi
  done

  die "apksigner not found. Put it on PATH or set APKSIGNER/APKSIGNER_JAR."
}

run_apksigner() {
  if [[ "$APKSIGNER_MODE" == "jar" ]]; then
    java -jar "$APKSIGNER_PATH" "$@"
  else
    "$APKSIGNER_PATH" "$@"
  fi
}

manual_pass() {
  local description="$1"
  echo
  echo "$description"
  read -r -p "Type PASS to accept this gate: " answer
  if [[ "$answer" != "PASS" ]]; then
    echo "- FAIL: $description" >> "$REPORT"
    die "manual release gate not accepted."
  fi
  echo "- PASS: $description" >> "$REPORT"
}

[[ -n "$TAG" ]] || die "usage: ./scripts/run-release-gate.sh vMAJOR.MINOR.PATCH"

require_command git
require_command python3
require_command keytool
require_command java
require_command sha256sum

[[ -f "$EXPECTED_CERT_FILE" ]] || die "missing $EXPECTED_CERT_FILE"
EXPECTED_CERT="$(normalize_sha256 < "$EXPECTED_CERT_FILE")"
[[ "$EXPECTED_CERT" =~ ^[0-9a-f]{64}$ ]] || die "invalid signing certificate fingerprint in $EXPECTED_CERT_FILE"

version_output="$(python3 scripts/resolve-release-version.py "$TAG")"
VERSION_NAME="$(awk -F= '$1 == "version_name" {print $2}' <<< "$version_output")"
VERSION_CODE="$(awk -F= '$1 == "version_code" {print $2}' <<< "$version_output")"
[[ -n "$VERSION_NAME" && -n "$VERSION_CODE" ]] || die "could not resolve release version from $TAG"

branch="$(git branch --show-current)"
[[ "$branch" == "main" ]] || die "release gate must run from main (current: ${branch:-detached})"

if [[ -n "$(git status --porcelain --untracked-files=no)" ]]; then
  die "tracked worktree changes exist; release gate requires a clean main checkout."
fi

git fetch origin main --no-tags
HEAD_SHA="$(git rev-parse HEAD)"
ORIGIN_MAIN_SHA="$(git rev-pars origin/main)"
[[ "$HEAD_SHA" == "$ORIGIN_MAIN_SHA" ]] ||
  die "local main is not origin/main ($HEAD_SHA != $ORIGIN_MAIN_SHA). Pull before gating."

git submodule update --init --recursive
python3 scripts/verify-distribution.py
PLATFORM_SHA="$(git -C sailens rev-parse HEAD)"

[[ -f "$KEYSTORE" ]] || die "app-signing keystore not found: $KEYSTORE"
read -r -s -p "Sailens app-signing password: " SIGNING_PASSWORD
echo >&2
[[ -n "$SIGNING_PASSWORD" ]] || die "signing password must not be empty."

export SAILENS_KEYTOOL_STORE_PASSWORD="$SIGNING_PASSWORD"
KEYSTORE_CERT="$(
  keytool -exportcert \
    -keystore "$KEYSTORE" \
    -storetype PKCS12 \
    -alias "$KEY_ALIAS" \
    -storepass:env SAILENS_KEYTOOL_STORE_PASSWORD |
    python3 -c 'import hashlib, sys; print(hashlib.sha256(sys.stdin.buffer.read()).hexdigest())'
)"
KEYSTORE_CERT="$(printf '%s' "$KEYSTORE_CERT" | normalize_sha256)"
[[ "$KEYSTORE_CERT" == "$EXPECTED_CERT" ]] ||
  die "keystore certificate does not match the pinned Sailens signing identity ($KEYSTORE_CERT'!=$EXPECTED_CERT)."

echo "Building production-signed release candidate $TAG from $HEAD_SHA ..."
SAILENS_APP_SIGNING_KEYSTORE="$KEYSTORE" \
SAILENS_APP_SIGNING_STORE_PASSWORD="$SIGNING_PASSWORD" \
SAILENS_APP_SIGNING_KEY_ALIAS="$KEY_ALIAS" \
SAILENS_APP_SIGNING_KEY_PASSWORD="$SIGNING_PASSWORD" \
./gradlew :app:assembleRelease \
  -Psailens.versionName="$VERSION_NAME" \
  -Psailens.versionCode="$VERSION_CODE" \
  --no-configuration-cache \
  --stacktrace

unset SIGNING_PASSWORD
unset SAILENS_KEYTOOL_STORE_PASSWORD

APK="$ROOT/app/build/outputs/apk/release/app-release.apk"
[[ -s "$APK" ]] || die "release APK was not produced: $APK"

resolve_apksigner
APKSIGNER_OUTPUT="$(run_apksigner verify --verbose --print-certs "$APK")"
printf '%s\n' "$APKSIGNER_OUTPUT"
APK_CERT="$(
  sed -n 's/^.*certificate SHA-256 digest: //p' <<< "$APKSIGNER_OUTPUT" \
    head -n 1 |
    normalize_sha256
)"
[[ "$APK_CERT" =~ ^[0-9a-f]{64}$ ]] || die "could not read APK signer SHA-256."
[[ "$APK_CERT" == "$EXPECTED_CERT" ]] ||
  die "APK signer does not match pinned Sailens signing identity ($APK_CERT != $EXPECTED_CERT)."
APK_SHA="$(sha256sum "$APK" | awk '{print $1}')"

resolve_adb
if [[ -n "${ANDROID_SERIAL:-}" ]]; then
  state="$("$ADB_BIN" get-state 2>/dev/null | tr -d '\r')"
  [[ "$state" == "device" ]] || die "ANDROID_SERIAL=$ANDROID_SERIAL is not an authorized online device."
else
  mapfile -t devices < <("$ADB_BIN" devices | tr -d '\r' | awk 'NR > 1 && $2 == "device" {print $1}')
  (( ${#devices[@]} == 1 )) ||
    die "exactly one authorized device is required; found ${#devices[@]}. Set ANDROID_SERIAL when multiple devices are connected."
  export ANDROID_SERIAL="${devices[0]}"
fi

DEVICE_MODEL="$("$ADB_BIN" shell getprop ro.product.model | tr -d '\r')"
DEVICE_MANUFACTURER="$("$ADB_BIN" shell getprop ro.product.manufacturer | tr -d '\r')"
DEVICE_SDK="$("$ADB_BIN" shell getprop ro.build.version.sdk | tr -d '\r')"
DEVICE_ANDROID="$("$ADB_BIN" shell getprop ro.build.version.release | tr -d '\r')"
DEVICE_ABI="$("$ADB_BIN" shell getprop ro.product.cpu.abi | tr -d '\r')"
DEVICE_SOC_MANUFACTURER="$("$ADB_BIN" shell getprop ro.soc.manufacturer | tr -d '\r')"
DEVICE_SOC_MODEL="$("$ADB_BIN" shell getprop ro.soc.model | tr -d '\r')"

[[ "$DEVICE_SDK" =~ ^[0-9]+$ ]] || die "could not read device SDK."
(( DEVICE_SDK >= 31 ))YH™]šXÙHÑÈ	U’PÑWÔÑÈ\È™[ÝÈØZ[[œÈZ[”ÙÈÌKˆ‚–ÖÈ‰U’PÑWÐP’HˆOH˜\›M]ŽHˆWHYH™]šXÙHš[X\žHP’H\È	U’PÑWÐP’NÈ™[X\ÙH™\]Z\™\È\›M]ŽKˆ‚‚”‘TÔ•ÑTH‰“ÓÕÙ\ÝÜ™[X\ÙKYØ]KÉÕQßKIÒPQÔÒNŒŒLŸH‚›ZÙ\ˆ\‰‘TÔ•ÑTˆ‚”‘TÔ•H‰‘TÔ•ÑT‹Ü™\Ü›Y‚“ÑÐÐUH‰‘TÔ•ÑT‹ÛÙØØ]‚ÔTÒÓÑÏH‰‘TÔ•ÑT‹ØÜ˜\Ú‚’S”ÕSÓÑÏH‰‘TÔ•ÑT‹Ú[œÝ[‚”ÕT•ÓÑÏH‰‘TÔ•ÑT‹ÜÝ\‚‚˜Ø]ˆ‰‘TÔ•ˆSÑ‚ˆÈØZ[[œÈ™[X\ÙHØ]H8 %	QÂ‚ˆÈÈØ[™Y]B‚‹H™\Ý[ˆSˆ“ÑÔ‘TÔÂ‹H›ÙXÝÛÛ[Z]ˆ	PQÔÒW‹H]›Ü›HÛÛ[Z]ˆ	U“Ô“WÔÒW‹H™\œÚ[Ûˆ˜[YNˆ	‘T”ÒSÓ—ÓSQW‹H™\œÚ[ÛˆÛÙNˆ	‘T”ÒSÓ—ÐÓÑW‹HTÈÒKLMŽˆ	T×ÔÒW‹H\\ÚYÛš[™ÈÙ\YšXØ]HÒKLMŽˆ	T×ÐÑT•‚ˆÈÈ]šXÙB‚‹HÙ\šX[ˆ	S‘“ÒQÔÑT’PS‹HX[Y˜XÝ\™\Žˆ	U’PÑWÓPS•QPÕT‘T—‹H[Ù[ˆ	U’PÑWÓSÑS‹H[™›ÚYˆ	U’PÑWÐS‘“ÒQ‹HÑÎˆ	U’PÑWÔÑ×‹HP’Nˆ	U’PÑWÐP’W‹HÛÐÈX[Y˜XÝ\™\Žˆ	U’PÑWÔÓÐ×ÓPS•QPÕT‘T—‹HÛÐÈ[Ù[ˆ	U’PÑWÔÓÐ×ÓSÑS‚ˆÈÈXXÚ[™HÚXÚÜÂ‚‹HTÔÎˆÛX[ˆØØ[XZ[—^XÝHX]Ú\ÈÜšYÚ[‹ÛXZ[—‚‹HTÔÎˆ\ÝšX][ÛˆÛÛ˜XÝ[™[™Y[Ù[\Ú\Ë‚‹HTÔÎˆ›ÙXÝ[ÛˆÙ^\ÝÜ™HX]Ú\È[›™YØZ[[œÈÚYÛš[™ÈY[]K‚‹HTÔÎˆZ[šYšYY™[X\ÙHTÈZ[Ú]™[X\ÙH™\œÚ[ÛˆY]Y]K‚‹HTÔÎˆTÈÚYÛ˜]\™H™\šYšY\È[™ÚYÛ™\ˆX]Ú\È[›™YØZ[[œÈÚYÛš[™ÈY[]K‚‹HTÔÎˆ\™Ù]]šXÙHØ]\ÙšY\ÈTKÐP’H›ÛÜ‹‚‚ˆÈÈX[X[ÚXÚÜÂ‘SÑ‚‚™XÚÂ™XÚÈ’[œÝ[[™È	TÈÛˆ	U’PÑWÓSÑS
	S‘“ÒQÔÑT’PS
H‹‹ˆ‚šYˆH‰Q—Ð’Sˆˆ[œÝ[\ˆ‰TÈˆˆ‰S”ÕSÓÑÈˆ‰ŒNÈ[‚ˆØ]‰S”ÕSÓÑÈˆ‰Œ‚ˆXÚÈ‰Œ‚ˆXÚÈ’Yˆ\È\ÈS”ÕSÑRSQÕTUWÒSÓÓTUP“KHXYËÛÝ\‹\ÚYÛ™YÛÛKœØZ[[œÈ\È[™XYH[œÝ[Yˆˆ‰Œ‚ˆXÚÈ•[š[œÝ[]X[X[HÛ›HYˆÛX\š[™È]\]H\ÈXØÙ\X›K[ˆ™\[ˆ\ÈØ]Kˆˆ‰Œ‚ˆ^]B™šB˜Ø]‰S”ÕSÓÑÈ‚‚”PÒÐQÑWÒS‘“ÏH‰
‰Q—Ð’SˆˆÚ[[\Þ\ÈXÚØYÙH‰PÒÐQÑWÓSQHˆˆY	×‰ÊH‚’S”ÕSQÕ‘T”ÒSÓ—ÐÓÑOH‰
ÙY[ˆ	ÜËËŠ™\œÚ[ÛÛÙOW
ÌNWVÌNWJ—
KŠ‹×KÜ	È‰PÒÐQÑWÒS‘“ÈˆXY[ˆJH‚’S”ÕSQÕ‘T”ÒSÓ—ÓSQOH‰
ÙY[ˆ	ÜË×–ÖÎœÜXÙN—WJ™\œÚ[Û“˜[YOKËÜ	È‰PÒÐQÑWÒS‘“ÈˆXY[ˆJH‚–ÖÈ‰S”ÕSQÕ‘T”ÒSÓ—ÐÓÑHˆOH‰‘T”ÒSÓ—ÐÓÑHˆWHˆYHš[œÝ[Y™\œÚ[ÛÛÙH	S”ÕSQÕ‘T”ÒSÓ—ÐÓÑHOH^XÝY	‘T”ÒSÓ—ÐÓÑKˆ‚–ÖÈ‰S”ÕSQÕ‘T”ÒSÓ—ÓSQHˆOH‰‘T”ÒSÓ—ÓSQHˆWHˆYHš[œÝ[Y™\œÚ[Û“˜[YH	S”ÕSQÕ‘T”ÒSÓ—ÓSQHOH^XÝY	‘T”ÒSÓ—ÓSQKˆ‚™XÚÈ‹HTÔÎˆ[œÝ[YXÚØYÙH	PÒÐQÑWÓSQW™\ÜÈ™\œÚ[Û“˜[YOIS”ÕSQÕ‘T”ÒSÓ—ÓSQH™\œÚ[ÛÛÙOIS”ÕSQÕ‘T”ÒSÓ—ÐÓÑKˆˆˆ‰‘TÔ•‚‚ˆ‰Q—Ð’SˆˆÙØØ]XÂˆ‰Q—Ð’SˆˆÚ[[H›Ü˜ÙK\ÝÜ‰PÒÐQÑWÓSQH‚ˆ‰Q—Ð’SˆˆÚ[[HÝ\UÈ[ˆ‰PRS—ÐPÕU’UHˆˆY	×‰ÈYH‰ÕT•ÓÑÈ‚œÛY\B”QH‰
‰Q—Ð’SˆˆÚ[YÙˆ‰PÒÐQÑWÓSQHˆˆY	×‰È]ÚÈ	ÞÜš[	_IÊH‚–ÖÈ[ˆ‰QˆWHYH‰PÒÐQÑWÓSQH\È›Ý[›š[™Èš]™HÙXÛÛ™ÈY\ˆ][˜Úˆ‚™XÚÈ‹HTÔÎˆ][˜Ú\ˆXÝ]š]HÝ\Y[™›ØÙ\ÜÈ™[XZ[™Y[]™HY\ˆ[š]X[][˜Úˆˆˆ‰‘TÔ•‚‚›X[X[Ü\ÜÈ•H™[X\ÙHRHÜ[™YÚ]Ý]H˜][ÛÛ™šYÝ\˜][ÛˆÝ]KØ[Y\˜H\›Z\ÜÚ[Û‹Ùš\œÝ\[ˆ[™[™ÈÛÜšÙY[™ÝZY[˜ÙHÛÝ[™HÝ\Yˆ‚›X[X[Ü\ÜÈ”™]Z[™YÛ›ÝÛ‹\ØÙ[™H]šY[˜ÙH›Üˆ\ÙH^XÝ[Ù[\Ú\ÈÛÛ™š\›\ÈÙ[X[XÈÚ[›™[Ü™\ˆ
Ú]\ØØ\\È˜Z[’YÈ]Z[š[][H›ØYLÚY]Ø[ÏLK\œÛÛLLJH[™]XÝ[ÛˆÛ\ÜÈYX[š[™Ëˆ‚›X[X[Ü\ÜÈH™X[Ø[Y\˜HOˆÙ[H
È]OˆÝZY[˜ÙHÙ\ÜÚ[Ûˆ˜[ˆÛÛ[[Ý\ÛH›Üˆ]X\ÝÛÈZ[]\ÈÛˆ\È]šXÙHÚ]Ý]Ü˜\ÚÝXÚÈ[˜[\Ú\ËÜˆÜÜÈÙˆÝZY[˜ÙKˆ‚›X[X[Ü\ÜÈ”ÜYXÚÝ]]Ø\ÈXÝX[HX\™›ÝYÚH[[™YËÕ[Ð˜XÚÈÛÛ™šYÝ\˜][Ûˆ[™Y›ÝÚ[[H˜Z[ˆ‚›X[X[Ü\ÜÈ’\XÈÝ]]Ø\È\ÚXØ[H™[›ÜˆHÝZY[˜ÙKÙ˜Z[\™HÝYH]\È^XÝYÈšXœ˜]Kˆ‚›X[X[Ü\ÜÈÝ\œ™[Ø[YKXÛÛ[Z]]šXÙH]šY[˜ÙHÚÝÜÈ›ÈX]\šX[™YÜ™\ÜÚ[Ûˆœ›ÛHHXØÙ\Y\™›Ü›X[˜ÙKØ˜XÚÙ[™˜\Ù[[™NÈ˜]]™HÙ[KÙ]ÜÝ›ØÙ\ÜÈ˜\Ý]È™[XZ[ˆ[XÝÚ\™HXYÛ›ÜÝXÜÈØ[ˆØœÙ\™H[Kˆ‚›X[X[Ü\ÜÈ•H[[™YX›XÈ\ÙKÙ\ÝšX][Ûˆ\È™Y[ˆÚXÚÙYYØZ[œÝHÝ\œ™[[Ù[\›Ý™[˜[˜ÙH\›\Ë[˜ÛY[™ÈHÚ]\ØØ\\È›Û‹XÛÛ[Y\˜ÚX[™\ÝšXÝ[Û‹ˆ‚‚ˆ‰Q—Ð’SˆˆÙØØ]Y]ˆ™XY[YHˆ‰ÑÐÐUˆYBˆ‰Q—Ð’SˆˆÙØØ]YXˆÜ˜\Ú]ˆ™XY[YHˆ‰ÔTÒÓÑÈˆYB‚”QÐQ•TH‰
‰Q—Ð’SˆˆÚ[YÙˆ‰PÒÐQÑWÓSQHˆˆY	×‰È]ÚÈ	ÞÜš[	_IÊH‚–ÖÈ[ˆ‰QÐQ•TˆˆWHYH‰PÒÐQÑWÓSQH\È›ÈÛ™Ù\ˆ[›š[™ÈY\ˆHX[X[Ù\ÜÚ[Û‹ˆ‚‚šYˆÜ™\\ZH‰PÒÐQÑWÓSQHˆ‰ÔTÒÓÑÈŽÈ[‚ˆXÚÈ‹HRSˆÜ˜\ÚY™™\ˆÛÛZ[œÈ	PÒÐQÑWÓSQKˆˆˆ‰‘TÔ•‚ˆYH˜Ü˜\ÚY™™\ˆÛÛZ[œÈ	PÒÐQÑWÓSQNÈ[œÜXÝ	ÔTÒÓÑËˆ‚™šB‚šYˆÜ™\Q\ZH	Õ[œØ]\ÙšYY[šÑ\œ›ÜŸ›È[\[Y[][Ûˆ›Ý[™›ÜŸ“’HUPÕQT”“ÔŸÜ[ˆ˜Z[Y˜][ÚYÛ˜[ÒQÊÑQÕŸP”•
IÈ‰ÑÐÐUŽÈ[‚ˆXÚÈ‹HRSˆÙØØ]ÛÛZ[œÈH˜]]™KÒ“’H˜][]\›ˆY\ˆ][˜Úˆˆˆ‰‘TÔ•‚ˆYH›˜]]™KÒ“’H˜][]\›ˆ›Ý[™È[œÜXÝ	ÑÐÐUˆ‚™šB‚˜Ø]ˆ‰‘TÔ•ˆSÑ‚‚ˆÈÈš[˜[™\Ý[‚ŠŠ”TÔÊŠ‚‚“XXÚ[™HÚXÚÜÈ[™H^XÚ]HXØÙ\YX[X[™[X\ÙHÚXÚÜÈ\ÜÙY›Üˆ\ÈØ[™Y]K‚‚•\ÈXÚØYÚ[™ËÙ]šXÙHØ]HÙ\È›Ý™\XÙHHœ›ØY\ˆ\™Ù]]\Ù\ˆ[™\ÙHHÝZY[˜ÙK]˜[Y][Û‚ÛÜšÈ˜XÚÙY[ˆH[›™YØZ[[œÈ[™›ÚYØÝ[Y[][Û‹‚‘SÑ‚‚™XÚÂ™XÚÈ”™[X\ÙHØ]HTÔËˆ‚™XÚÈ”™\Üˆ	‘TÔ•‚™XÚÈTÎˆ	TÈ‚™XÚÈ”ÚYÛ™\Žˆ	T×ÐÑT•‚™XÚÂ™XÚÈ‘È›Ý\ÚH™[X\ÙHYÈ[[[ÝH]™H™]šY]ÙY[™™]Z[™Y\È™\ÜÙ]šY[˜ÙKˆ‚