# Releasing Sailens

This document is the operational runbook. The long-lived versioning, signing and distribution contract is defined in [`release-policy.md`](release-policy.md).

The current official distribution channel is **GitHub Releases**. A release tag produces a signed,
installable APK in a **Draft Release**; the exact APK is made public only after the physical-device
gate passes. Google Play publishing is currently **pending** and is deliberately not part of the tag
workflow.

## Signing identity

The GitHub APK must use a long-lived **app signing key**, not a disposable CI key and not a future
Google Play upload key.

Android only accepts an in-place update when the application ID matches and the new APK is signed
by the same signing identity (or a valid signing-key rotation). Because the GitHub APK establishes
the installed app's signing identity, losing or replacing this key can strand existing sideload
installations.

For future Google Play distribution, keep the same app signing identity across channels: configure
Play App Signing with a copy of this app signing key, then create a **separate upload key** for
signing AABs sent to Play. Do not use the GitHub app signing key as the routine Play upload key.
The production signing identity is pinned in `release/app-signing-certificate.sha256`:

`0d364c8aace36fce5c345b3e88857080c4fb0c8ffc6482d3059ee88abf67e499`

The tag workflow verifies both the configured PKCS12 secret and the built APK against this
fingerprint. A mismatch stops the release before any artifact is exposed publicly.


## Signing key and GitHub secrets

The production PKCS12 key has already been created and its public certificate fingerprint is now
part of the repository contract. **Do not generate a replacement key.** Keep at least one offline
backup of `~/.sailens/signing/sailens-app-signing.p12` and store the password separately.

If the GitHub Actions signing secrets ever need to be refreshed, restore/use the pinned PKCS12 and
run from WSL/Linux:

```bash
./scripts/setup-github-signing.sh
```

The helper verifies the local certificate against `release/app-signing-certificate.sha256` before
it is allowed to update any secret. If the local PKCS12 is missing, it fails and tells the operator
to restore the offline backup rather than silently creating a new signing identity.

The repository secrets are:

- `SAILENS_APP_SIGNING_KEYSTORE_BASE64`
- `SAILENS_APP_SIGNING_STORE_PASSWORD`
- `SAILENS_APP_SIGNING_KEY_ALIAS`
- `SAILENS_APP_SIGNING_KEY_PASSWORD`

The private key and passwords must never be committed or pasted into issues, PRs, chat, logs, or
release notes.

## Version contract

Release tags must be:

```text
vMAJOR.MINOR.PATCH
```

The workflow derives:

```text
versionName = MAJOR.MINOR.PATCH
versionCode = MAJOR * 1,000,000 + MINOR * 1,000 + PATCH
```

`MINOR` and `PATCH` must each be at most 999, and the derived Android `versionCode` must fit
within Android's allowed range. Examples:

```text
v1.0.0   -> versionCode 1000000
v1.2.3   -> versionCode 1002003
v2.0.0   -> versionCode 2000000
```

A release tag must point to a commit reachable from `origin/main`.


## Updating the Sailens Android platform pin

The exact `sailens/` gitlink is a release identity boundary. Dependabot checks it daily, but every
bump still requires review of the upstream commit range and the distribution host mirror. Manual
updates are also supported, including the important case where a platform PR was squash-merged and
the app must re-pin to the new post-merge `sailens-android/main` SHA.

Use the dedicated bilingual runbook:

- [Updating the Sailens Android submodule](updating-sailens-android.md)
- [更新 Sailens Android submodule（简体中文）](updating-sailens-android.zh-CN.md)

Do not create a product release tag while an intended platform bump is still pointing at a
pre-merge feature-branch commit.


## Before creating a release tag

Before tagging:

- `main` CI must be green;
- the production PKCS12 must have an offline backup;
- model provenance and the Cityscapes non-commercial restriction must have been reviewed for the
  intended distribution;
- known-scene evidence for the exact bundled model hashes must still support the expected semantic
  channel/class meanings;
- there must be an authorized physical arm64 Android device available for the exact-artifact gate.

Do not treat CI's disposable signing-key smoke as production-device evidence.


## Publishing a GitHub release

Release is deliberately two-stage so the APK tested on the physical device is the exact APK users
will download.

### 1. Create the tag and Draft Release

From the intended `main` commit:

```bash
git switch main
git pull --ff-only
git tag -a v1.0.0 -m "Sailens 1.0.0"
git push origin v1.0.0
```

The `Release` workflow then:

1. verifies the tag belongs to `main` and checks the distribution/model contracts;
2. materializes the PKCS12 secret and verifies its certificate fingerprint against the pinned
   production signing identity;
3. builds/tests/lints the minified release APK;
4. verifies the built APK signer against the same pinned identity;
5. creates `release-manifest.json` with product/platform/model/APK hashes and signer fingerprint;
6. creates the combined corresponding-source archive;
7. creates or updates a **Draft GitHub Release** containing:
   - `sailens-VERSION.apk`
   - `release-manifest.json`
   - `sailens-VERSION-source.tar.gz`

The workflow intentionally stops while the release is still private/draft.

### 2. Gate the exact Draft APK on a physical device

On the Windows development machine, with exactly one authorized physical Android device connected:

```powershell
.\scripts\run-release-gate.ps1 v1.0.0
```

The gate downloads the Draft assets with `gh` and verifies the tag/manifest/source commit, artifact
hashes and signer before installing anything. It then checks API/ABI, installs the exact Draft APK,
checks the installed version, launches `com.sailens`, and retains install/start/logcat/crash
evidence under:

```text
dist/release-gate/<tag>-<commit>/
```

ADB cannot truthfully prove perception semantics, audible speech, physical vibration, or whether a
real scene was interpreted safely, so the script requires explicit `PASS` confirmation for:

- first-run/camera permission and required-Guidance startup;
- known-scene semantic channel/class meaning for the exact model hashes;
- at least two minutes of real camera -> sem + det -> Guidance operation;
- actual TTS/TalkBack output;
- actual haptic output;
- no material performance/backend regression in current same-commit evidence;
- the current model/licence constraints, including Cityscapes non-commercial use.

It also fails on a dead app process, crash-buffer evidence for `com.sailens`, or common
JNI/native fatal patterns.

This packaging/device gate does **not** replace the broader target-user and Phase A guidance
validation tracked in Sailens Android.

### 3. Publish only after the exact-artifact gate passes

After reviewing and retaining the generated evidence:

```bash
gh release edit v1.0.0 --repo wnbotoo/sailens-app --draft=false
```

Until that command runs, the tagged release stays Draft and is not the public download.

## Installing and updating the APK

The release APK targets arm64 Android devices with Android 12 / API 31 or newer.

Users can download `sailens-VERSION.apk` from the GitHub Release page and install it after allowing
their browser or file manager to install apps from that source. Developers can install it with:

```bash
adb install sailens-VERSION.apk
```

A later GitHub release can update an existing installation in place when it keeps
`applicationId = com.sailens`, uses the same app signing key, and has a compatible higher
`versionCode`.

## Google Play status: pending

Do not add Play publishing back to the tag workflow until the new Play developer account and the
`com.sailens` application identity are ready.

When Play distribution resumes:

1. keep the GitHub app signing key as the cross-channel app signing identity;
2. configure Play App Signing using a copy of that same app signing key;
3. create a separate Play **upload key** and store it separately from the app signing key;
4. add a separate AAB / Play publishing workflow rather than coupling Play availability to GitHub
   Releases;
5. verify the Play-delivered APK signing certificate matches the release-manifest fingerprint before
   treating Play as an update path for existing GitHub installs.

If the new Play account cannot reuse the `com.sailens` package identity, resolve that identity
issue before promising cross-channel in-place updates.

## Model replacement rule

The current historical TFLite files expose Ultralytics version and parent export arguments in their
embedded metadata, but not every transitive exporter package version. Any future model replacement
must preserve a stronger recipe: canonical input checkpoint/hash, exact export command, pinned
Ultralytics/TensorFlow/onnx2tf/ONNX environment, output hash, semantic channel-order evidence and
device runtime/performance evidence.
