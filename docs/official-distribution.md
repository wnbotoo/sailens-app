**English** | [简体中文](official-distribution.zh-CN.md)

# Official Sailens Android distribution positioning

> Status: **accepted target; implementation intentionally deferred.** This repository is still named
> `sailens-yolo` and the current application identity still represents the YOLO Edition. A separate
> follow-up change will perform the repository/product identity migration after this documentation is
> merged.

The authoritative cross-repository decision is in Sailens Android:
[`sailens/docs/distribution-model.md`](../sailens/docs/distribution-model.md).

## 1. Product role

This repository is the **official first-party Sailens Android distribution**.

Sailens Android (`wnbotoo/sailens-android`) implements reusable capabilities. This repository
selects, configures, packages, validates and releases those capabilities as the end-user product.

The intended app-store product name is simply:

> **Sailens**

This is not a second platform and not a fork of the platform. It should remain a thin host.

## 2. Target identity

| Item | Current | Accepted target |
|---|---|---|
| Repository | `wnbotoo/sailens-yolo` | `wnbotoo/sailens-app` |
| Product name | Sailens YOLO Edition | **Sailens** |
| Android namespace | `com.sailens` | `com.sailens` |
| applicationId | `com.sailens.yolo` | `com.sailens` |
| Platform dependency | `sailens-android` submodule | unchanged |
| Distribution mechanism | Gradle composite build | unchanged |
| Current licence | AGPL-3.0 | unchanged by branding alone |

The repository is renamed **in place**. It is not deleted/recreated and does not get another
fresh-root history.

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

The current repository name and product name expose "YOLO" because this distribution was originally
defined around its bundled models.

Under the accepted positioning, model architecture is an implementation/provenance detail rather
than the product identity. After the migration:

- users see **Sailens**, not "YOLO Edition";
- YOLO/Ultralytics names remain in model provenance, attribution, compatibility and licence records;
- the current `YOLO_EDITION_NOTICE*` material is reorganised into model/distribution notices rather
  than discarded;
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

## 8. Planned follow-up implementation

After this documentation lands, a separate positioning change will:

1. rename the repository in place from `sailens-yolo` to `sailens-app`;
2. change `applicationId` from `com.sailens.yolo` to `com.sailens`;
3. keep namespace `com.sailens`;
4. change the user-facing product name to **Sailens**;
5. update `APP_SOURCE_URL`, About identity and identity tests;
6. rename/reframe YOLO Edition notices as model provenance/distribution notices;
7. update README/AGENTS/build/release/store references to the new repository identity;
8. verify debug/release build and device installation;
9. verify it can coexist with the Sailens Android reference host after that host moves to
   `com.sailens.reference`.

No platform architecture change is required for this migration.
