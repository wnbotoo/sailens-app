# Releasing Sailens

The current official distribution channel is **GitHub Releases**. A release tag produces a signed,
installable APK that users can download and install directly. Google Play publishing is currently
**pending** and is deliberately not part of the tag workflow.

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

## One-time GitHub signing setup

Preferred path: clone/update the repository on the machine where you want to create and retain the
private signing key, then run:

```bash
./scripts/setup-github-signing.sh
```

The script:

- creates (or explicitly reuses) `~/.sailens/signing/sailens-app-signing.jks` by default;
- uses a 4096-bit RSA key with a 10,000-day validity period;
- asks for signing passwords with hidden terminal input and does not put them in shell history;
- uses Java `keytool` environment-password inputs instead of passing passwords as command-line
  arguments;
- prints the public signing-certificate SHA-256;
- asks again before writing anything to GitHub;
- uses `gh secret set` to create/update the four repository Actions secrets;
- verifies only the resulting secret **names**. GitHub does not expose secret values back to the
  script.

Prerequisites:

```text
keytool   JDK tool
python3
gh        authenticated with GitHub
```

If needed, authenticate first with:

```bash
gh auth login
```

The script configures these repository secrets:

- `SAILENS_APP_SIGNING_KEYSTORE_BASE64`
- `SAILENS_APP_SIGNING_STORE_PASSWORD`
- `SAILENS_APP_SIGNING_KEY_ALIAS`
- `SAILENS_APP_SIGNING_KEY_PASSWORD`

The private keystore and passwords must never be committed. **Before the first public release,
create an offline backup of the keystore and store its passwords separately.** The public
signing-certificate SHA-256 is recorded in every `release-manifest.json`; retain that fingerprint
when configuring future Play App Signing.

To use a different local key directory, repository, keystore path or alias, set the corresponding
environment variable before running the script:

```text
SAILENS_SIGNING_DIR
SAILENS_GITHUB_REPOSITORY
SAILENS_APP_SIGNING_KEYSTORE_PATH
SAILENS_APP_SIGNING_KEY_ALIAS_VALUE
```

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

## Pre-tag release gate

Do not create the tag until the exact candidate has passed the product/device checks that hosted CI
cannot prove:

- semantic channel order validated on known scenes;
- packaged model preflight and Guidance-required startup behavior;
- real camera -> sem/det -> Guidance session on a physical arm64 device;
- minified release smoke, including JNI/RegisterNatives loading;
- TTS and haptic output;
- current device performance/backend baseline recorded and checked for regressions;
- current model-provenance and licensing constraints reviewed, especially Cityscapes
  non-commercial use.

The platform documentation records known pre-existing performance gaps. The release gate is to avoid
silently regressing the accepted baseline, not to pretend those known gaps already hold.

## Publishing a GitHub release

After the gate is complete:

```bash
git switch main
git pull --ff-only
git tag -a v1.0.0 -m "Sailens 1.0.0"
git push origin v1.0.0
```

The `Release` workflow then:

1. checks out the tagged commit and exact `sailens/` submodule;
2. verifies the tag format, that the commit belongs to `main`, the distribution contract and model
   hashes;
3. builds/tests/lints a minified release APK signed with the long-lived app signing key;
4. verifies the APK with Android `apksigner` and records the signing-certificate SHA-256;
5. creates `release-manifest.json` with the product commit, exact Sailens Android commit, model
   hashes/embedded exporter metadata, APK hash and signing fingerprint;
6. creates a combined corresponding-source archive containing this exact Sailens app tag plus the
   exact Sailens Android source pinned at `sailens/`;
7. creates a draft GitHub Release containing:
   - `sailens-VERSION.apk`
   - `release-manifest.json`
   - `sailens-VERSION-source.tar.gz`
8. publishes the GitHub Release only after all artifacts have been created successfully.

No Google Play API call is made.

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
