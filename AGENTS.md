# AGENTS.md — Official Sailens Android distribution

```text
Repository:  wnbotoo/sailens-app
Product:     Sailens
License:     AGPL-3.0 under the current bundled-model choices
Platform:    wnbotoo/sailens-android (Apache-2.0)
Namespace:   com.sailens
applicationId: com.sailens
```

This repository is **not a fork**. It is the thin first-party Sailens application over Sailens
Android's `sailens-*` libraries, consumed through a Gradle composite build. Sailens Android is
pinned as the `sailens/` git submodule; that exact commit is the platform version boundary.

Do not publish the platform modules to Maven as part of ordinary application work. Source/composite
consumption is deliberate until a stable external SDK surface and independent consumers justify a
separate Maven-distribution milestone.

## Ownership boundary

Reusable capability belongs in Sailens Android:

- camera/runtime/vision infrastructure;
- Guidance and Describe implementation;
- output/accessibility mechanisms;
- reusable shell and capability/preflight model;
- generic native/runtime/model support.

This repository owns distribution choices:

- the thin Android host;
- `applicationId = "com.sailens"` and the Sailens product identity;
- official bundled model weights;
- capability expectations (currently Guidance required);
- supported/default product configuration;
- release/store/signing metadata;
- distribution and model-provenance notices.

If behaviour would be useful to another Sailens consumer, implement it in Sailens Android and take
it here through a submodule bump after licence review. Do not duplicate platform code locally.

## What is here

```text
app/                         official host, identity and weights
app/src/main/assets/         sem.tflite, det.tflite — tracked deliberately
docs/model-provenance.md     exact model provenance/licence records
DISTRIBUTION_NOTICE.md       distribution licence/source obligations
docs/official-distribution.md product/repository contract
sailens/                     Sailens Android git submodule
settings.gradle.kts          includeBuild("sailens") + platform version catalog
```

The bundled weights are intentionally tracked here and intentionally absent from Sailens Android.
Never "fix" the platform by committing these models there.

"YOLO" is model provenance, **not** product branding. Keep Ultralytics/model-specific facts in
`docs/model-provenance.md` and `DISTRIBUTION_NOTICE.md`; do not reintroduce "YOLO Edition" as an
app/repository identity.

## Identity guardrail

`app/build.gradle.kts` must keep:

```text
namespace     = com.sailens
applicationId = com.sailens
APP_LICENSE    = AGPL-3.0
APP_SOURCE_URL = https://github.com/wnbotoo/sailens-app
```

Sailens Android's reference host uses `com.sailens.reference`. This is what lets both installs
coexist while reserving the plain `com.sailens` identity for the shipping product.

`DistributionIdentityTest` pins the package, licence and source URL. If host code is synced from
Sailens Android, those values must remain distribution-owned.

## Working on it

```powershell
$env:ANDROID_HOME = "C:/Users/wnbot/AppData/Local/Android/Sdk"
git submodule update --init
.\gradlew.bat --no-daemon :app:assembleDebug
```

For release-relevant changes also verify release build, instrumentation tests and a real arm64
device. Model changes must follow `docs/model-provenance.md`, including the manual semantic
channel-order gate and device performance checks.

The full positioning decisions are in `docs/official-distribution.md` and
`sailens/docs/distribution-model.md`.
