# Sailens — YOLO Edition

Navigation assistance for blind and low-vision users: a camera-fed perception pipeline that turns
the scene ahead into speech and haptics.

This repository is the **YOLO Edition**, distributed under **AGPL-3.0**. It is a thin application
over the Core Edition libraries and it packages the model weights that Core Edition deliberately
does not ship. See [YOLO_EDITION_NOTICE.md](YOLO_EDITION_NOTICE.md) for the licence boundary and
the trademark disclaimer.

## Accepted target positioning

This repository is becoming the **official first-party Sailens Android distribution**. The
long-term app-store product name is **Sailens**; "YOLO" becomes model provenance rather than product
branding.

The accepted follow-up identity is:

```text
repository:    wnbotoo/sailens-app   (rename this repository in place)
namespace:     com.sailens           (unchanged)
applicationId: com.sailens
product name:  Sailens
```

The current repository/application identity is intentionally left unchanged in this documentation
change. See [docs/official-distribution.md](docs/official-distribution.md) for the staged migration,
ownership boundary and release policy. The cross-repository decision is
[`sailens/docs/distribution-model.md`](sailens/docs/distribution-model.md).

## Structure

```text
app/       the edition: host wiring, identity, expectations, model weights
docs/      provenance and licences of the bundled weights (yolo-models.md)
sailens/   Core Edition (wnbotoo/sailens-android), as a git submodule
```

Core Edition is consumed through a Gradle composite build, not a fork. The submodule commit is the
version boundary — there is no Maven publication and no artifact version.

## Build

```bash
git clone --recurse-submodules https://github.com/wnbotoo/sailens-yolo.git
cd sailens-yolo
./gradlew :app:assembleDebug
```

If you cloned without `--recurse-submodules`:

```bash
git submodule update --init
```

`ANDROID_HOME` must point at an Android SDK. The build produces an arm64-v8a APK.

## Relationship to Core Edition

Platform work — capture, runtime, vision, guidance, output, the presentation shell — happens in
[Core Edition](https://github.com/wnbotoo/sailens-android) and arrives here as a submodule bump.
This repository owns what is genuinely its own: the weights, the application identity, and the
declaration that navigation assistance is required rather than optional.

Code does not flow back the other way without a licence review.
