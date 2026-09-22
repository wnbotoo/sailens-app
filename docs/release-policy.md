# Sailens Release and Versioning Policy

This document defines the long-lived release policy for the official Sailens Android distribution
(`wnbotoo/sailens-app`). Operational commands and the physical-device checklist live in
[`docs/releasing.md`](releasing.md).

## Product version

Sailens product releases use tags in this exact form:

```text
vMAJOR.MINOR.PATCH
```

The first public release is planned as:

```text
v0.1.0
```

The current release tooling intentionally accepts only three numeric components. Pre-release and
build metadata such as `v0.1.0-beta.1`, `v0.1.0-rc.1`, or `v0.1.0+build.5` are not part of the
current contract.

### Meaning of 0.x

`0.x` means Sailens is publicly distributable but the product contract is still evolving.

Before `v1.0.0`:

- `PATCH` releases are for fixes and other changes that are not intended to change the product
  contract materially.
- `MINOR` releases may add capabilities and may also contain intentional product/runtime/model
  contract changes while the product is still stabilizing.
- `MAJOR` remains `0` until the project is ready to declare a stable `1.0` product contract.

After `v1.0.0`, releases should follow normal semantic-versioning expectations: breaking product
contract changes require a MAJOR increment, backward-compatible features increment MINOR, and
backward-compatible fixes increment PATCH.

Examples:

```text
v0.1.0   first public release
v0.1.1   fix to the 0.1 line
v0.2.0   next pre-1.0 product iteration
v1.0.0   first stable 1.x product contract
```

## Android version mapping

The release tag is the source of truth. The workflow derives:

```text
versionName = MAJOR.MINOR.PATCH

versionCode =
    MAJOR * 1,000,000
  + MINOR * 1,000
  + PATCH
```

`MINOR` and `PATCH` must each be in `0..999`. The derived Android `versionCode` must be in
`1..2,100,000,000`.

Examples:

```text
tag       versionName   versionCode
v0.1.0    0.1.0         1000
v0.1.1    0.1.1         1001
v0.2.0    0.2.0         2000
v1.0.0    1.0.0         1000000
v1.2.3    1.2.3         1002003
```

Release tags must point to commits reachable from `main`.

Once a release tag has been pushed, do not retarget it to another commit. If a candidate is rejected
after tagging, fix the problem on `main` and create a new version tag.

## Product repository vs platform repository

The public product version belongs to **`sailens-app`**.

`sailens-android` is the reusable platform and does not need to share the product's version number.
A Sailens product release pins an exact Sailens Android git commit through the `sailens/` submodule.

Every release manifest records:

- the exact `sailens-app` commit;
- the exact `sailens-android` submodule commit;
- the bundled model hashes and embedded exporter metadata;
- the released APK hash;
- the app-signing certificate fingerprint;
- the corresponding-source archive hash.

This keeps product versioning independent from platform development while making every distributed
binary reproducible as a source/version identity.

## Production signing identity

The Sailens Android application identity is:

```text
applicationId: com.sailens
```

The production app-signing key is a long-lived identity for this application. It is not a generic
key for other products.

The current production certificate SHA-256 is pinned in
[`release/app-signing-certificate.sha256`](../release/app-signing-certificate.sha256):

```text
0d364c8aace36fce5c345b3e88857080c4fb0c8ffc6482d3059ee88abf67e499
```

The private PKCS12 keystore is kept outside the repository and must have an offline backup.

GitHub Actions contains the same production signing material as encrypted repository secrets:

```text
SAILENS_APP_SIGNING_KEYSTORE_BASE64
SAILENS_APP_SIGNING_STORE_PASSWORD
SAILENS_APP_SIGNING_KEY_ALIAS
SAILENS_APP_SIGNING_KEY_PASSWORD
```

The private key is never committed to Git. The repository contains only the public certificate
fingerprint.

Release automation must reject:

- a configured keystore whose certificate does not match the pinned fingerprint;
- an APK whose signer does not match the pinned fingerprint.

If the local PKCS12 is lost, restore it from backup. Do not generate a replacement key as a normal
release operation.

## GitHub release contract

GitHub Releases are the current official distribution channel. Google Play distribution is pending.

A release is deliberately split into two trust boundaries:

```text
main
  -> version tag
  -> CI builds and signs exact artifacts
  -> Draft GitHub Release
  -> physical-device gate downloads that exact Draft APK
  -> explicit publication
```

Pushing a valid version tag does **not** immediately expose a public APK.

The tag workflow creates a Draft Release containing:

```text
sailens-VERSION.apk
release-manifest.json
sailens-VERSION-source.tar.gz
```

The physical-device gate then validates the exact Draft APK rather than rebuilding another local
binary. Only after that exact artifact passes the gate is the GitHub Release made public.

The operational procedure is documented in
[`docs/releasing.md`](releasing.md).

## Physical-device gate

The gate combines machine-verifiable checks with explicit human checks.

Machine-verifiable checks include:

- tag/source identity;
- release manifest identity;
- APK and corresponding-source hashes;
- production signer fingerprint;
- Android API and ABI floor;
- installed package version;
- initial process survival;
- crash-buffer evidence;
- common JNI/native fatal patterns.

Human confirmation remains required for behavior that ADB cannot establish honestly:

- first-run/camera permission and required-Guidance startup;
- semantic channel/class meaning for the exact bundled model hashes;
- real camera -> semantic + detection -> Guidance operation;
- audible TTS/TalkBack behavior;
- physical haptic behavior;
- current performance/backend regression evidence;
- current model-provenance and licence constraints.

The gate is an exact release-artifact check. It does not replace broader target-user or safety
validation.

## Future Google Play distribution

Google Play publishing is currently pending and is not part of the tag workflow.

When Play distribution is introduced:

- keep the same Sailens app-signing identity so existing GitHub installations can remain on a
  compatible update path;
- configure Play App Signing around that existing app-signing identity;
- create a separate **upload key** for routine AAB uploads;
- do not treat the Play upload key as the Sailens app-signing key;
- verify the Play-delivered signing certificate against the pinned Sailens certificate fingerprint
  before declaring GitHub -> Play update compatibility.

GitHub publication must continue to work independently of Play availability.
