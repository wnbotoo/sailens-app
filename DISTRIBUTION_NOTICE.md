**English** | [简体中文](DISTRIBUTION_NOTICE.zh-CN.md)

# Sailens Distribution Notice

This repository is the **official Sailens Android distribution** and is distributed under
**AGPL-3.0** under its current bundled-model choices.

The reusable Android platform is maintained separately:

```text
Sailens Android
Repository: https://github.com/wnbotoo/sailens-android
License: Apache-2.0

Official Sailens distribution
Repository: https://github.com/wnbotoo/sailens-app
License: AGPL-3.0
```

The distribution consumes Sailens Android as the `sailens/` git submodule through a Gradle
composite build. Reusable feature development belongs in Sailens Android and arrives here through
an exact submodule bump. This repository owns the thin product host, bundled models, product
identity, capability expectations and release material.

## License boundary

Sailens Android remains Apache-2.0 and ships no model weights.

This distribution bundles model material whose current licensing/provenance leads the distributed
application to be released under AGPL-3.0. Distributing a build from this repository therefore
requires complying with AGPL-3.0, including providing complete corresponding source for the exact
build. That source includes the exact Sailens Android commit pinned by the `sailens/` submodule.

Model files also carry their own upstream and training-dataset terms. Those obligations are
independent of the platform code licence and do not disappear because the product is branded
simply as Sailens.

Do not move distribution-specific or model-covered material into Sailens Android unless a licence
review confirms that the change can be clearly licensed under Apache-2.0.

This is a project contribution/reuse rule. It does not by itself limit a copyright holder's use of
material for which that holder owns the relevant rights. Contributions from other authors remain
subject to the rights and licences that apply to those contributions.

## Current model provenance

The current bundled models are documented in
[`docs/model-provenance.md`](docs/model-provenance.md).

The current bundle includes YOLO-family model material. Accordingly:

> **Not affiliated with, endorsed by, or sponsored by Ultralytics.** "YOLO" is used descriptively
> in model provenance to identify the models integrated by this distribution. Ultralytics
> trademarks, where they exist, belong to their owner; nothing here implies review, approval or
> endorsement by them.

"YOLO" is model provenance, not the Sailens product name.

## Model record requirements

Every bundled model must document:

```text
1. Model name
2. Model version
3. Upstream project
4. Upstream source / derivation source (exact download URL when downloaded; otherwise the canonical source checkpoint plus export metadata/recipe)
5. Code licence
6. Weights licence
7. Training dataset licence, if known
8. Redistribution terms
9. Commercial-use terms
10. Export format and runtime target
```

## Release source requirements

Every distributed Sailens build from this repository must provide:

```text
1. Complete corresponding source code
2. Build scripts and build instructions
3. AGPL-3.0 licence file
4. Third-party dependency licence notices
5. Bundled-model provenance and licence notices
6. A matching git tag for the released build
7. The exact Sailens Android submodule commit used by the build
```

## About-screen identity

The application identifies itself as:

```text
Sailens
License: AGPL-3.0
Source code: https://github.com/wnbotoo/sailens-app
```

Model files and third-party dependencies may have additional terms; see this notice and the model
provenance document.
