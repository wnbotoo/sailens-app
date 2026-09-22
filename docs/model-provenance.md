**English** | [简体中文](model-provenance.zh-CN.md)

# Bundled models: provenance and licenses

> This document satisfies the model record requirements in `../DISTRIBUTION_NOTICE.md`. **It is not
> legal advice**; have someone familiar with open-source licensing review it before release.
>
> The models' **technical contract** (shape / layout / class order / performance red lines) is in
> Sailens Android's [`models.md`](../sailens/docs/models.md). This document only covers **what these two weights are, where
> they came from, and under what license**.

## What is bundled

```text
app/src/main/assets/sem.tflite      semantic walkable-area segmentation
app/src/main/assets/det.tflite      obstacle detection
```

Sailens Android git-ignores `app/src/main/assets/*.tflite` because it ships zero weights; here they
are tracked as ordinary files. They are what makes this official distribution AGPL-3.0.

## Provenance audit status

The 2026-09-22 release audit separates the **canonical upstream checkpoint** for the recorded model
identity from the **exact bundled export artifact**:

- **Canonical upstream model identities are verified.** Ultralytics publishes `yolo26n.pt` and
  `yolo26n-sem.pt` from the official `ultralytics/assets` `v8.4.0` release. The exact
  checkpoint URLs and SHA-256 values for those model identities are listed below. This identifies
  the canonical upstream weights; the TFLite file format does not cryptographically bind itself to
  a source-checkpoint SHA.
- **The bundled artifacts identify their exporter.** Both TFLite files contain Ultralytics
  `metadata.json` written by **Ultralytics 8.4.52**, including export timestamps, task, image
  size and export arguments. Those values are recorded below and are printed by
  `scripts/verify-distribution.py` in CI.
- The selected files are the legacy onnx2tf `*_float16.tflite` siblings from a TFLite export
  bundle. Their embedded metadata records the parent export invocation as `int8=true`,
  `half=false`. In Ultralytics 8.4.52, that invocation asks onnx2tf to generate additional
  integer-quantized artifacts while the float variants are still produced; the same export
  metadata is appended to every generated TFLite. Therefore `int8=true` in metadata does **not**
  mean these selected `*_float16.tflite` files have INT8 I/O. The tensor contract below remains
  the authority for the selected artifact.
- **Exact historical transitive exporter versions were not recorded.** The embedded metadata pins
  Ultralytics itself, but not the exact TensorFlow / onnx2tf / ONNX dependency versions that were
  present on 2026-06-03. Bit-for-bit regeneration of the old TFLite bytes is therefore not
  guaranteed from historical tooling alone. This is an audit limitation, not a release-build
  reproducibility gap: the exact TFLite bytes are source-controlled in this repository and CI
  verifies their SHA-256 before building.
- The public `ultralytics/yolo-flutter-app` release assets inspected during this audit, including
  `v0.2.0` and `v0.3.5`, do not provide an exact filename/hash/size match for these two FP16
  files. Those releases are **context, not the download source for these exact artifacts**.

For a future model replacement, pin the complete export environment and retain the recipe with the
new artifact. A public release of the current model bundle still requires acceptance of the
Cityscapes non-commercial terms and the manual semantic-order/device runtime gates below.

## sem.tflite

| Field | Value |
|---|---|
| Model name | `yolo26n-sem` |
| Original file name | `yolo26n-sem_float16.tflite` |
| sha256 | `69e240a9b7ba81b83cef1ffc0bac77698a47a37544c7517259b9accd599ab4f5` |
| Upstream project | Ultralytics YOLO26 |
| Canonical upstream checkpoint | `yolo26n-sem.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n-sem.pt |
| Canonical checkpoint sha256 | `f3f293cca764de1f93044030d8d5612de9c5ffbf37c9c8ea1b69418b73038999` |
| Bundled artifact derivation | Embedded metadata identifies a legacy Ultralytics **8.4.52** TFLite export; the exact artifact is retained in this repository and identified by the SHA-256 above. No separate upstream TFLite download URL is claimed |
| Model version / release tag | Canonical checkpoint: `ultralytics/assets v8.4.0`; bundled artifact exporter: **Ultralytics 8.4.52** |
| Embedded export timestamp | `2026-06-03T18:04:36.645162` |
| Embedded parent export args | `task=semantic`, `batch=1`, `imgsz=640x640`, `data=cityscapes8.yaml`, `fraction=1.0`, `int8=true`, `half=false`, `nms=false`, `end2end=false` |
| Code license | AGPL-3.0 (Ultralytics) |
| Weights license | AGPL-3.0 (per Ultralytics' position; whether copyleft applies to weights is contested in the industry — this repository takes the strict reading of their claim) |
| Training dataset | Cityscapes (19 trainId classes) |
| Dataset license | 🔴 **NON-COMMERCIAL**. This constraint travels with the weights and is independent of any code license |
| Redistribution | Permitted only subject to **both** layers: AGPL-3.0 obligations **and** Cityscapes' rule that a trained model may be distributed only as an abstract derivative that does not allow recovery of the dataset; commercial use of the dataset or derivative work is not permitted |
| Commercial use | 🔴 **Not permitted** (Cityscapes dataset constraint). A free app has a "non-commercial" argument; **any commercialization, including selling hardware, requires replacing this with a sem model trained on commercially usable data** |
| Export format | Legacy Ultralytics TensorFlow/TFLite export via onnx2tf; selected `yolo26n-sem_float16.tflite` sibling, NHWC |
| I/O | FLOAT32 `[1,640,640,3]` → `Identity` FLOAT32 `[1,640,640,19]` dense scores |
| Runtime target | LiteRT, GPU |

## det.tflite

| Field | Value |
|---|---|
| Model name | `yolo26n` |
| Original file name | `yolo26n_float16.tflite` |
| sha256 | `5950fac5e1a92adb17ad907b3925943c5c9dd29d59b0cbc1391efb4eb72740cf` |
| Upstream project | Ultralytics YOLO26 |
| Canonical upstream checkpoint | `yolo26n.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n.pt |
| Canonical checkpoint sha256 | `9b09cc8bf347f0fc8a5f7657480587f25db09b34bf33b0652110fb03a8ad4fef` |
| Bundled artifact derivation | Embedded metadata identifies a legacy Ultralytics **8.4.52** TFLite export; the exact artifact is retained in this repository and identified by the SHA-256 above. No separate upstream TFLite download URL is claimed |
| Model version / release tag | Canonical checkpoint: `ultralytics/assets v8.4.0`; bundled artifact exporter: **Ultralytics 8.4.52** |
| Embedded export timestamp | `2026-06-03T19:59:11.798570` |
| Embedded parent export args | `task=detect`, `batch=1`, `imgsz=640x640`, `data=coco128.yaml`, `fraction=1.0`, `int8=true`, `half=false`, `nms=false`, `end2end=false` |
| Code license | AGPL-3.0 (Ultralytics) |
| Weights license | AGPL-3.0 (as above) |
| Training dataset | COCO (80 classes) |
| Dataset license | Annotations are CC BY 4.0; images carry their own source terms. ⚠️ **Review before release** |
| Redistribution | Permitted, under AGPL-3.0 |
| Commercial use | Looser than sem (COCO has no non-commercial clause), but **still bound by the AGPL weights** |
| Export format | Legacy Ultralytics TensorFlow/TFLite export via onnx2tf; selected `yolo26n_float16.tflite` sibling, NHWC |
| I/O | FLOAT32 `[1,640,640,3]` → `Identity` FLOAT32 `[1,84,8400]` (RAW_TRANSPOSED) |
| Runtime target | LiteRT, GPU |

## 🔴 The longest pole

**sem's Cityscapes non-commercial constraint is the hardest wall on this project's path to
commercialization, and no amount of repository splitting solves it** — it travels with the
**weights**, not the code license. Free distribution has a "non-commercial" argument; **selling
hardware is unambiguously commercial, and at that point sem must be replaced with a model trained on
commercially usable data.** This is unrelated to the A/B split — do not mistake "the core is Apache
now" for this problem being solved too.

## Required steps when changing a model

1. Run `py sailens/scripts/inspect_tflite.py <path>` and check it against the contract in
   [`models.md`](../sailens/docs/models.md).
2. **Verify class channel order semantics by hand.** Sailens Android's `SemanticModelPreflight`
   (sailens-guidance) checks that the output parses and that its class count matches the declared
   taxonomy — **it cannot check class order**. A wrong order does not error; it will quietly call
   a sidewalk a road, out loud, to someone who cannot see it. Test the argmax output on a known
   scene before discussing accuracy.
3. Update all ten fields in this document (including the sha256).
4. Build and launch this official distribution. It declares Guidance required, so a model whose output does not
   parse or whose class count is wrong stops at the fatal configuration screen before anyone can
   press start — that is the contract guard now. Sailens Android's own suite covers the check itself:
   `./gradlew :sailens:sailens-guidance:testDebugUnitTest` from this repository's root.
5. Re-check Sailens Android's performance red lines on a device (`sailens/docs/architecture.md`
   §12.3): `sem: postprocessBackend = "native_score"` and `outputReadTimeMs ≈ 0`;
   `det: postprocessBackend = "native_bbox_nms_float_handle"`.
   **Sailens Android has no weights and cannot verify these — this is the only place they can be
   checked.** §12.3 records which of them currently hold; a line already recorded as not holding
   there is a known pre-existing gap, not a regression from the new model.
