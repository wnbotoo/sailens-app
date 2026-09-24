# Sailens

Navigation assistance for blind and low-vision users: a camera-fed perception pipeline turns the
scene ahead into speech and haptics.

This repository is the **official first-party Sailens Android distribution**. It is the application
intended for end users and app-store releases under the product name **Sailens**.

The reusable Android platform lives in
[`wnbotoo/sailens-android`](https://github.com/wnbotoo/sailens-android) and is consumed here as the
`sailens/` git submodule through a Gradle composite build. This repository stays thin: it owns the
product host and identity, official model bundle, capability expectations, release configuration and
distribution-specific notices.

**Current distribution licence: AGPL-3.0.** The platform remains Apache-2.0; the stronger
distribution licence comes from the current bundled-model/licensing choices. See
[`DISTRIBUTION_NOTICE.md`](DISTRIBUTION_NOTICE.md) and
[`docs/model-provenance.md`](docs/model-provenance.md).

## Identity

```text
repository:    wnbotoo/sailens-app
product name:  Sailens
namespace:     com.sailens
applicationId: com.sailens
```

The Sailens Android reference host uses `applicationId = "com.sailens.reference"`, so both can be
installed side by side.

## Structure

```text
app/                         thin official host, identity, expectations and model weights
app/src/main/assets/         sem.tflite, det.tflite
docs/model-provenance.md     bundled-model provenance and licence records
DISTRIBUTION_NOTICE.md       distribution/licence boundary and release-source requirements
sailens/                     Sailens Android, pinned as an exact git submodule commit
settings.gradle.kts          includeBuild("sailens") + Sailens Android's version catalog
```

The submodule commit is the platform version boundary for a product build. The `sailens-*`
libraries are not published to Maven in the current phase.

For the automatic and manual update procedure, including squash-merge handling and host-mirror
validation, see [Updating the Sailens Android submodule](docs/updating-sailens-android.md)
([简体中文](docs/updating-sailens-android.zh-CN.md)).

## Build

```bash
git clone --recurse-submodules https://github.com/wnbotoo/sailens-app.git
cd sailens-app
./gradlew :app:assembleDebug
```

If cloned without submodules:

```bash
git submodule update --init
```

`ANDROID_HOME` must point at an Android SDK. The build produces an arm64-v8a APK.

## Platform relationship

Reusable work — capture, runtime, vision, Guidance, Describe, output, accessibility and the
presentation shell — belongs in Sailens Android and arrives here through an exact submodule bump
after the appropriate licence review.

This repository owns only distribution choices: bundled models, product identity, required
capabilities, supported defaults and release material. It must not grow a parallel implementation
of the Sailens platform.

The current official distribution declares **Guidance required**. Missing or incompatible packaged
Guidance models are therefore static configuration failures rather than a legal zero-pipeline state.

## Model provenance

"YOLO" is not part of the Sailens product brand. It appears only where technically and legally
relevant to the current bundled models. Full hashes, upstream sources, model/dataset licences and
release gates are in [`docs/model-provenance.md`](docs/model-provenance.md).

## Product/distribution contract

See [`docs/official-distribution.md`](docs/official-distribution.md). The authoritative
cross-repository policy is also present in the pinned platform checkout at
[`sailens/docs/distribution-model.md`](sailens/docs/distribution-model.md).

## Releases

GitHub Releases are the current official distribution channel. Pushing a semantic-version tag such
as `v1.0.0` builds a **signed, installable APK**, records the exact platform/model/artifact hashes
and signing-certificate fingerprint, attaches corresponding source, and creates a **Draft Release**.
The exact Draft APK must pass the physical-device release gate before the Release is made public.

Google Play publication is currently **pending** while the developer account is re-established. The
tag workflow does not call Google Play. When Play distribution is added later, it must preserve the
same app-signing identity so existing GitHub-installed copies can be updated in place.

See [`docs/release-policy.md`](docs/release-policy.md) for the versioning/signing/distribution
contract and [`docs/releasing.md`](docs/releasing.md) for the exact operational release procedure.
