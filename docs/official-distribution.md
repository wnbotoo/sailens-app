**English** | [简体中文](official-distribution.zh-CN.md)

# Official Sailens Android distribution positioning

> Status: **Android product identity implemented; GitHub repository rename pending.** This is the
> first-party Sailens Android distribution. Its Android identity is already the plain
> `com.sailens` application ID. After final validation, rename the existing GitHub repository in
> place from `sailens-yolo` to `sailens-app`.

The authoritative cross-repository decision is in Sailens Android:
[`sailens/docs/distribution-model.md`](../sailens/docs/distribution-model.md).

## 1. Product role

This repository is the **official first-party Sailens Android distribution**.

Sailens Android (`wnbotoo/sailens-android`) implements reusable capabilities. This repository
selects, configures, packages, validates and releases those capabilities as the end-user product.

The intended app-store product name is simply:

> **Sailens**

This is not a second platform and not a fork of the platform. It should remain a thin host.

## 2. Product identity

| Item | Identity |
|---|---|
| Repository | `wnbotoo/sailens-app` after the pending in-place rename |
| Product name | **Sailens** |
| Android namespace | `com.sailens` |
| applicationId | `com.sailens` |
| Platform dependency | `sailens-android` submodule |
| Distribution mechanism | Gradle composite build |
| Current licence | AGPL-3.0 |

The namespace remains `com.sailens`; the product rename does not justify moving Kotlin packages.

## 3. What this repository owns

The official distribution owns product decisions and release material:

- the thin Android host and first-party application identity;
- the official bundled models;
- model hashes, provenance, attribution and licence records;
- which Sailens capabilities are required by an official release;
- supported/default runtime and perception configuration;
- release signing and release-channel configuration;
- product icon/name, store metadata and distribution-specific privacy/release configuration;
- release tags and release notes.

The current distribution declares Guidance required. A broken or incompatible packaged Guidance
model is therefore a broken distribution and must fail static configuration validation rather than
quietly behave like the zero-model reference host.

## 4. What stays in Sailens Android

Reusable implementation belongs upstream in Sailens Android:

- camera/runtime/vision infrastructure;
- Guidance and Describe capability implementation;
- shared output/accessibility mechanisms;
- the reusable shell;
- generic model/runtime abstractions;
- native code and reusable tests.

If this repository needs generally useful behaviour, implement it in Sailens Android and consume it
here with a submodule bump after licence review. Do not let the official app grow a parallel copy of
the platform.

## 5. YOLO becomes provenance, not product branding

This distribution was originally defined around its bundled YOLO models, which is why the old
repository/product identity exposed "YOLO". The Android product branding has now been migrated;
only the GitHub repository rename remains pending.

Model architecture is an implementation/provenance detail rather than the product identity:

- users see **Sailens**, not "YOLO Edition";
- YOLO/Ultralytics names remain in model provenance, attribution, compatibility and licence records;
- model/distribution obligations are recorded in `DISTRIBUTION_NOTICE.md` and
  `docs/model-provenance.md`;
- bundled model obligations remain in force even though "YOLO" leaves the product name.

This matters because the official model bundle can change in the future without forcing a product
rename.

## 6. Source dependency and version boundary

This repository continues to consume Sailens Android from source:

```text
sailens-app
├── app/
├── app/src/main/assets/
└── sailens/ -> wnbotoo/sailens-android @ exact main SHA
```

`settings.gradle.kts` continues to use:

```kotlin
includeBuild("sailens")
```

There is no Maven publication in the current phase. The pinned Sailens Android commit is the
platform version boundary for an app release.

A product release should record:

```text
Sailens v1.x.y
├── Sailens Android @ <main SHA>
├── semantic model @ <version/hash/provenance>
├── detection model @ <version/hash/provenance>
└── official product configuration
```

The app repository owns product versioning/tags. Sailens Android does not need Maven artifact
versions for this relationship.

## 7. Licence boundary

Sailens Android remains Apache-2.0 and zero-weights.

This official distribution currently remains AGPL-3.0 because of the models and licensing choices
it bundles. The product rename does not weaken or remove those obligations. The current model
provenance documents remain release-critical.

If the official model bundle changes later, the distribution licence may be re-evaluated separately
with appropriate legal review.

## 8. Implemented identity boundary

The distribution uses:

```text
repository:    wnbotoo/sailens-app
product:       Sailens
namespace:     com.sailens
applicationId: com.sailens
source:        https://github.com/wnbotoo/sailens-app
```

The Sailens Android reference host uses `com.sailens.reference`, so the two applications remain
installable side by side. The platform architecture, package names, composite-build mechanism and
capability model are unchanged by this product-positioning migration.
