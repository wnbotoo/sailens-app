# Releasing Sailens to Google Play

This document covers the official `wnbotoo/sailens-app` release path. The workflow intentionally
stops at Google Play **Internal testing**. Production promotion is a separate human decision in Play
Console.

## One-time setup

1. Create the `com.sailens` application in Google Play Console and enroll it in **Play App
   Signing**.
2. Create and securely back up a dedicated **upload key**. The CI workflow never needs the Play app
   signing key; it signs the AAB with the upload key, then Play App Signing signs the APKs delivered
   to users.
3. Base64-encode the upload keystore and configure these GitHub Actions secrets:
   - `SAILENS_UPLOAD_KEYSTORE_BASE64`
   - `SAILENS_UPLOAD_STORE_PASSWORD`
   - `SAILENS_UPLOAD_KEY_ALIAS`
   - `SAILENS_UPLOAD_KEY_PASSWORD`
4. Create a Google service account for the Android Publisher API, grant it access to the Sailens app
   in Play Console, and store its JSON credentials as:
   - `PLAY_SERVICE_ACCOUNT_JSON`
5. Complete Play Console's app-content, privacy, store-listing and testing prerequisites before the
   first tag-driven upload.

The upload keystore and service-account JSON are secrets. Do not commit either file or their decoded
contents.

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

## Publishing an internal release

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
3. builds/tests/lints a release signed with the upload key;
4. verifies the AAB signature;
5. generates `release-manifest.json` with the product commit, exact Sailens Android commit, model
   hashes/embedded exporter metadata and AAB hash;
6. creates a combined corresponding-source archive containing this exact Sailens app tag plus the
   exact Sailens Android source pinned at `sailens/`;
7. creates a **draft** GitHub Release containing the signed AAB, manifest and combined source
   archive;
8. uploads that same AAB plus the R8 mapping file to Google Play **Internal testing**;
9. publishes the GitHub Release only after the Play upload succeeds.

If Play upload fails, the GitHub Release remains a draft for inspection. Do not move the release to
Production from CI.

## Human promotion

After Internal testing, inspect the Play Console artifact, automated checks and physical-device
behavior. Promotion to closed/open testing or Production is deliberately manual. This keeps store
rollout, policy declarations and user exposure separate from build automation.

## Model replacement rule

The current historical TFLite files expose Ultralytics version and parent export arguments in their
embedded metadata, but not every transitive exporter package version. Any future model replacement
must preserve a stronger recipe: canonical input checkpoint/hash, exact export command, pinned
Ultralytics/TensorFlow/onnx2tf/ONNX environment, output hash, semantic channel-order evidence and
device runtime/performance evidence.
