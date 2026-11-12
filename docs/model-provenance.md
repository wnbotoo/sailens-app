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

Both files are **Ultralytics' own published LiteRT exports**, taken unmodified. The audit separates
three things:

- **The exact bundled bytes are an upstream release asset.** Each file is byte-identical to an asset
  of the official `ultralytics/yolo-flutter-app` release `v0.6.6`: GitHub's server-side SHA-256
  digest of the asset equals the sha256 recorded below. Both assets were uploaded on
  `2026-07-23T20:19:03Z` by ultralytics/yolo-flutter-app#568, which re-exported and replaced all
  35 LiteRT assets of that release. Release assets can be replaced, as #568 itself shows, so the
  sha256 here, not the URL, is the identity of what this repository ships.
- **The export recipe is the upstream script.** `scripts/export-tflite-models.py` at the #568
  merge commit `42f141eec748` exports each model with
  `YOLO("<model>.pt").export(format="litert", quantize="w8a32", nms=False, end2end=False, imgsz=640, batch=1)`:
  Ultralytics' `format=litert` path (litert-torch conversion, ai-edge-quantizer), where `w8a32`
  means INT8 weights with FP32 activations and needs no calibration data. The embedded
  `metadata.json` agrees: written by **Ultralytics 8.4.104**, `args.quantize = "w8a32"`, and printed
  by `scripts/verify-distribution.py` in CI.
- **Exact transitive exporter versions are not recorded.** Ultralytics 8.4.104's `export-litert`
  extra only requires `litert-torch>=0.9.0`, `ai-edge-litert>=2.1.4` and
  `ai-edge-quantizer>=0.6.0`; neither the file (its flatbuffer carries no converter version) nor the
  upstream release records which versions were installed. Bit-for-bit regeneration is therefore not
  guaranteed. This is an audit limitation, not a release-build reproducibility gap: the exact bytes
  are downloadable from upstream, source-controlled in this repository, and CI verifies their
  SHA-256 before building.
- **Canonical upstream model identities are linked by identity, not by hash.** The embedded
  metadata identifies YOLO26n trained on COCO and YOLO26n-sem trained on Cityscapes, with class
  names in the contract's order. Ultralytics publishes those checkpoints as `yolo26n.pt` and
  `yolo26n-sem.pt` in the official `ultralytics/assets` `v8.4.0` release (URLs and SHA-256 below).
  The upstream script loads the checkpoint by name; the TFLite file format does not
  cryptographically bind itself to a source-checkpoint SHA.

This distribution is permanently non-commercial (see the positioning in
[`DISTRIBUTION_NOTICE.md`](../DISTRIBUTION_NOTICE.md)); its public releases accept the Cityscapes
non-commercial terms on that basis.

## sem.tflite

| Field | Value |
|---|---|
| Model name | `yolo26n-sem` |
| Original file name | `yolo26n-sem_w8a32.tflite` |
| sha256 | `d29dee0289f29be7e1446095e843109cdff7bdddba9bfd2ffd525425fbc5f557` |
| Size | 1,748,412 bytes |
| Upstream project | Ultralytics YOLO26 |
| Canonical upstream checkpoint | `yolo26n-sem.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n-sem.pt |
| Canonical checkpoint sha256 | `f3f293cca764de1f93044030d8d5612de9c5ffbf37c9c8ea1b69418b73038999` |
| Bundled artifact source | `ultralytics/yolo-flutter-app` release `v0.6.6` asset `yolo26n-sem_w8a32.tflite`, uploaded `2026-07-23T20:19:03Z` by ultralytics/yolo-flutter-app#568; its GitHub digest equals the sha256 above |
| Bundled artifact URL | https://github.com/ultralytics/yolo-flutter-app/releases/download/v0.6.6/yolo26n-sem_w8a32.tflite |
| Export recipe | `scripts/export-tflite-models.py` at `ultralytics/yolo-flutter-app@42f141eec748`: `format=litert`, `quantize=w8a32`, `nms=False`, `end2end=False`, `imgsz=640`, `batch=1` |
| Model version / release tag | Canonical checkpoint: `ultralytics/assets v8.4.0`; bundled artifact: `yolo-flutter-app v0.6.6`, exported by **Ultralytics 8.4.104** |
| Embedded export timestamp | `2026-07-23T20:42:42.194490` (exporter's local time, no zone) |
| Embedded export args | `task=semantic`, `batch=1`, `imgsz=640x640`, `quantize=w8a32`, `data=null`, `fraction=1.0`, `end2end=false` |
| Code license | AGPL-3.0 (Ultralytics; the embedded metadata states `AGPL-3.0 License`, and `ultralytics/yolo-flutter-app` is AGPL-3.0) |
| Weights license | AGPL-3.0 (per Ultralytics' position; whether copyleft applies to weights is contested in the industry — this repository takes the strict reading of their claim) |
| Training dataset | Cityscapes (19 trainId classes) |
| Dataset license | 🔴 **NON-COMMERCIAL**. This constraint travels with the weights and is independent of any code license |
| Redistribution | Permitted only subject to **both** layers: AGPL-3.0 obligations **and** Cityscapes' rule that a trained model may be distributed only as an abstract derivative that does not allow recovery of the dataset; commercial use of the dataset or derivative work is not permitted |
| Commercial use | 🔴 **Not permitted** (Cityscapes dataset constraint). This distribution is free and permanently non-commercial, which is what allows it to bundle this model. **Any commercial use, including selling hardware, is out of scope for this repository**: a commercial product would be a separate application with a sem model trained on commercially usable data |
| Export format | Ultralytics LiteRT export (`format=litert`: litert-torch + ai-edge-quantizer), `w8a32` (INT8 weights, FP32 activations), NCHW. Chosen over the legacy onnx2tf float16 NHWC export of the same checkpoint, which runs on the LiteRT GPU without an error and computes wrongly there ("Accelerator result consistency" in [`models.md`](../sailens/docs/models.md)) |
| I/O | FLOAT32 `[1,3,640,640]` → FLOAT32 `[1,19,640,640]` dense scores (NCHW) |
| Runtime target | LiteRT, GPU |

## det.tflite

| Field | Value |
|---|---|
| Model name | `yolo26n` |
| Original file name | `yolo26n_w8a32.tflite` |
| sha256 | `d9cef07ce652ccfa9ce58e4ac8a4df98ff037739a9dad20a8afcae21b545df73` |
| Size | 2,875,553 bytes |
| Upstream project | Ultralytics YOLO26 |
| Canonical upstream checkpoint | `yolo26n.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n.pt |
| Canonical checkpoint sha256 | `9b09cc8bf347f0fc8a5f7657480587f25db09b34bf33b0652110fb03a8ad4fef` |
| Bundled artifact source | `ultralytics/yolo-flutter-app` release `v0.6.6` asset `yolo26n_w8a32.tflite`, uploaded `2026-07-23T20:19:03Z` by ultralytics/yolo-flutter-app#568; its GitHub digest equals the sha256 above |
| Bundled artifact URL | https://github.com/ultralytics/yolo-flutter-app/releases/download/v0.6.6/yolo26n_w8a32.tflite |
| Export recipe | `scripts/export-tflite-models.py` at `ultralytics/yolo-flutter-app@42f141eec748`: `format=litert`, `quantize=w8a32`, `nms=False`, `end2end=False`, `imgsz=640`, `batch=1` |
| Model version / release tag | Canonical checkpoint: `ultralytics/assets v8.4.0`; bundled artifact: `yolo-flutter-app v0.6.6`, exported by **Ultralytics 8.4.104** |
| Embedded export timestamp | `2026-07-23T20:40:41.640955` (exporter's local time, no zone) |
| Embedded export args | `task=detect`, `batch=1`, `imgsz=640x640`, `quantize=w8a32`, `data=null`, `fraction=1.0`, `end2end=false` |
| Code license | AGPL-3.0 (Ultralytics; as for sem) |
| Weights license | AGPL-3.0 (as above) |
| Training dataset | COCO (80 classes) |
| Dataset license | Annotations are CC BY 4.0; images carry their own source terms. ⚠️ **Review before release** |
| Redistribution | Permitted, under AGPL-3.0 |
| Commercial use | Looser than sem (COCO has no non-commercial clause), but **still bound by the AGPL weights** |
| Export format | Ultralytics LiteRT export (`format=litert`: litert-torch + ai-edge-quantizer), `w8a32` (INT8 weights, FP32 activations), NCHW. Chosen over the legacy onnx2tf float16 NHWC export, as for sem |
| I/O | FLOAT32 `[1,3,640,640]` → FLOAT32 `[1,84,8400]` (RAW_TRANSPOSED); boxes in `NORMALIZED` units, the `DetectionModelConfig` default |
| Runtime target | LiteRT, GPU |

## Verification of the bundled files

The checks the "Required steps" below ask for, as they came out for these two files:

| Check | Result |
|---|---|
| Tensor contract (`inspect_tflite.py`) | sem: one FLOAT32 input `[1,3,640,640]`, one FLOAT32 output `[1,19,640,640]`. det: one FLOAT32 input `[1,3,640,640]`, one FLOAT32 output `[1,84,8400]`. Single float output tensors, the contract the zero-copy fast paths need |
| sem class order | The embedded `names` are `CityscapesTaxonomy`'s 19 classes in the same order. On the CPU (LiteRT 2.1.5, x86-64), the argmax agrees with the legacy float16 export of the same checkpoint on 92–100% of pixels over four synthetic inputs; a permuted channel order would disagree almost everywhere |
| det class order | The embedded `names` are the COCO 80 order; every id `CocoTaxonomy` names (person 0 … potted plant 58) carries that label |
| det box units | On the CPU, over four synthetic inputs, every anchor's centre lies between 0.002 and 1.081 and every width and height below 1, so the boxes are `NORMALIZED`, the `DetectionModelConfig` default; no configuration change |
| Model consistency check, OnePlus CPH2747 (SM8850, Android 16), LiteRT 2.1.5 GPU | **PASS**: sem GPU/CPU pixel agreement 0.964 on average, 0.933 on the lowest frame; det recall 1.0 with no extra detections (16 on the CPU, 16 on the GPU), pointed at the floor with an office chair in view. A first run without a detectable object in view was inconclusive (sem 0.940 / 0.873; det 7 of 7). The legacy export measured sem 0.391 and det 0 of 21 on the same phone |
| Known scene, same device | A 31-second indoor Guidance session in the debug build: ground recognised on 77% of frames (the legacy export, on the GPU: 3%, with `building` dominant on 99% of frames); people and an office chair detected |
| §12.3 red lines, same session | All hold: sem `native_score` with `outputReadTimeMs` 0 on all 547 sem runs; det `native_bbox_nms_float_handle` with `outputReadTimeMs` 0 on all 599 det runs; one of the two models reports `shared_native_yuv` on every frame |
| Frame budget, same session | Slower than the legacy export, which was fast and wrong: pipeline 43 ms median (p90 58) against 28 ms (p90 37), 22 output frames/s with 27% of camera frames dropped against 29/s and 0.3%. The difference is in sem: its postprocess, which waits for the GPU result, takes 26 ms median against 15 |

## 🔴 The longest pole

**sem's Cityscapes non-commercial constraint is why this distribution is non-commercial, and no
amount of repository splitting changes that** — it travels with the **weights**, not the code
license. This distribution is free and stays non-commercial. **Selling hardware is unambiguously
commercial; a commercial product would be a separate application with a sem model trained on
commercially usable data, never a release of this repository.** This is unrelated to the A/B split — do not mistake "the core is Apache
now" for this problem being solved too.

## Required steps when changing a model

1. Run `py sailens/scripts/inspect_tflite.py <path>` and check it against the contract in
   [`models.md`](../sailens/docs/models.md).
2. **Verify class channel order semantics by hand.** Sailens Android's `SemanticModelPreflight`
   (sailens-guidance) checks that the output parses and that its class count matches the declared
   taxonomy — **it cannot check class order**. A wrong order does not error; it will quietly call
   a sidewalk a road, out loud, to someone who cannot see it. Test the argmax output on a known
   scene before discussing accuracy.
3. Update all applicable provenance fields in this document (including the bundled-artifact sha256 and embedded export metadata).
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
6. Run the debug build's **Model consistency check** (Settings → Diagnostics) on every supported
   device: each model on its accelerator against the CPU, on live camera frames, judged by the
   bounds in "Accelerator result consistency" in [`models.md`](../sailens/docs/models.md). A model
   that runs on the GPU without an error can still answer wrongly there; Sailens Android has seen
   onnx2tf NHWC exports do exactly that on SM8850 and SM8450. Run it again when the LiteRT version
   or a supported device changes, not only the model. **Sailens Android has no weights, so for the
   models this distribution ships, this is the only place it can run.**
