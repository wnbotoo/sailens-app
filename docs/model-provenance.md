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
identity from **export-artifact provenance**:

- **Canonical upstream checkpoints are verified.** Ultralytics publishes `yolo26n.pt` and
  `yolo26n-sem.pt` from the official `ultralytics/assets` `v8.4.0` release. The exact
  checkpoint URLs and SHA-256 values for those recorded model identities are listed below. This
  identifies the canonical upstream weights, but does **not** by itself prove that the bundled
  TFLite bytes were exported from those exact checkpoint bytes.
- **The bundled TFLite export chain is not yet reproducible.** Repository history retained the
  bundled TFLite files, their hashes, filenames and technical contracts, but not the exact
  `ultralytics` / `onnx2tf` / TensorFlow versions or the complete export invocation that
  produced these bytes.
- The public `ultralytics/yolo-flutter-app` release assets inspected during this audit, including
  `v0.2.0` and `v0.3.5`, do not provide an exact filename/hash/size match for either bundled
  FP16 TFLite. Those releases are therefore **context, not the download source for these exact
  artifacts**.
- **Public v1 release remains blocked on this provenance gap.** Before release, either reproduce
  the current TFLite SHA-256 values from pinned source checkpoints and a pinned export toolchain, or
  replace the bundled models with newly generated, fully pinned artifacts and repeat the semantic
  channel-order and device runtime/performance release gates.

Do not turn a nearby upstream release into an exact source claim merely because its model family or
technical contract looks compatible.

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
| Bundled TFLite download source | ⚠️ **Unresolved** — no exact match was found in the inspected public `ultralytics/yolo-flutter-app` release assets |
| Model version / release tag | Canonical checkpoint: `ultralytics/assets v8.4.0`; exact bundled-TFLite derivation/export version: ⚠️ **unresolved** |
| Code license | AGPL-3.0 (Ultralytics) |
| Weights license | AGPL-3.0 (per Ultralytics' position; whether copyleft applies to weights is contested in the industry — this repository takes the strict reading of their claim) |
| Training dataset | Cityscapes (19 trainId classes) |
| Dataset license | 🔴 **NON-COMMERCIAL**. This constraint travels with the weights and is independent of any code license |
| Redistribution | Permitted only subject to **both** layers: AGPL-3.0 obligations **and** Cityscapes' rule that a trained model may be distributed only as an abstract derivative that does not allow recovery of the dataset; commercial use of the dataset or derivative work is not permitted |
| Commercial use | 🔴 **Not permitted** (Cityscapes dataset constraint). A free app has a "non-commercial" argument; **any commercialization, including selling hardware, requires replacing this with a sem model trained on commercially usable data** |
| Export format | onnx2tf float16 export, NHWC |
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
| Bundled TFLite download source | ⚠️ **Unresolved** — no exact match was found in the inspected public `ultralytics/yolo-flutter-app` release assets |
| Model version / release tag | Canonical checkpoint: `ultralytics/assets v8.4.0`; exact bundled-TFLite derivation/export version: ⚠️ **unresolved** |
| Code license | AGPL-3.0 (Ultralytics) |
| Weights license | AGPL-3.0 (as above) |
| Training dataset | COCO (80 classes) |
| Dataset license | Annotations are CC BY 4.0; images carry their own source terms. ⚠️ **Review before release** |
| Redistribution | Permitted, under AGPL-3.0 |
| Commercial use | Looser than sem (COCO has no non-commercial clause), but **still bound by the AGPL weights** |
| Export format | onnx2tf float16 export, NHWC |
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
