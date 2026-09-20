# AGENTS.md — Sailens YOLO Edition

```text
Repository: wnbotoo/sailens-yolo      Edition: YOLO Edition   License: AGPL-3.0
Upstream:   wnbotoo/sailens-android   Edition: Core Edition   License: Apache-2.0
```

**This repository is no longer a fork.** It is a thin application over Core Edition's
`sailens-*` libraries, consumed through a Gradle composite build. Core Edition is pinned as the
`sailens/` git submodule, and that submodule commit is the version boundary — nothing is published
to Maven.

Everything that existed only to keep a fork merge base is gone: the `merge=ours` driver, the
upstream sync recipe, the disabled push remote, the prefix-block convention in this file, and the
rule that this repository stay code-identical to upstream. Core Edition's own `AGENTS.md` lives at
`sailens/AGENTS.md` and applies to the code in that submodule.

## What is actually here

```text
app/                    the whole edition: host wiring, identity, weights
app/src/main/assets/    sem.tflite, det.tflite — tracked here, ignored upstream
sailens/                Core Edition, as a submodule
settings.gradle.kts     includeBuild("sailens") + Core Edition's version catalog
```

- **The weights are the point.** `app/src/main/assets/{sem,det}.tflite` are committed deliberately.
  Upstream ignores those same paths because it ships zero weights; here they are what makes this
  edition AGPL-3.0. Do not add an ignore rule for them, and do not "fix" upstream by proposing it
  commit models.
- **This edition declares Guidance required** (`app/.../SailensEdition.kt`,
  `guidanceRequired = true`). If the packaged model goes missing or its class definition stops
  matching, the app enters the fatal configuration state and says so out loud rather than starting
  up unable to guide anyone. That is the difference from upstream, which promises nothing.

## Working on it

```powershell
# ANDROID_HOME must be set; this clone has no local.properties.
$env:ANDROID_HOME = "C:/Users/wnbot/AppData/Local/Android/Sdk"
git submodule update --init
.\gradlew.bat --no-daemon :app:assembleDebug
```

- A change that belongs to the platform goes **upstream**, in the submodule's own repository, and
  arrives here as a submodule bump. A change that belongs to this edition — weights, identity,
  expectations, YOLO-specific decoding — goes in `app/`.
- Do not copy code from here into Core Edition unless a license review confirms it is free of
  AGPL-covered material. See `YOLO_EDITION_NOTICE.md`.
