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

Both files are **Ultralytics' own published LiteRT exports**, taken unmodified.

- **The bundled bytes match the official release assets.** GitHub lists the SHA-256 digests below
  for both assets in the [Ultralytics Flutter v0.7.0 release](https://github.com/ultralytics/yolo-flutter-app/releases/expanded_assets/v0.7.0).
  The hashes identify the bundled files if the upstream assets are replaced.
- **The export settings come from upstream.** The
  [export script at the v0.7.0 commit](https://github.com/ultralytics/yolo-flutter-app/blob/5c589835f436d14b74c1d503477c4ad455efe530/scripts/export-tflite-models.py)
  uses `format=litert`, `quantize=w8a32`, `nms=None`, and batch 1. These two assets have 640×640
  inputs and embedded metadata from **Ultralytics 8.4.188** with `end2end=false`. The `w8a32`
  export uses INT8 weights with FP32 activations.
- **The release records omit the exact transitive converter versions.** Builds use the exact
  upstream assets stored here, and CI verifies their SHA-256 before building.
- **Canonical upstream model identities are linked by identity, not by hash.** The embedded
  metadata identifies YOLO26n trained on COCO and YOLO26n-sem trained on Cityscapes, with class
  names in the contract's order. Ultralytics publishes those checkpoints as `yolo26n.pt` and
  `yolo26n-sem.pt` in the official `ultralytics/assets` `v8.4.0` release (URLs and SHA-256 below).
  The upstream script loads the checkpoint by name; the TFLite file format does not
  cryptographically bind itself to a source-checkpoint SHA.

The maintainers release this distribution as a permanently non-commercial project (see the
positioning in [`DISTRIBUTION_NOTICE.md`](../DISTRIBUTION_NOTICE.md)); its public releases accept
the Cityscapes non-commercial terms on that basis.

## sem.tflite

| Field | Value |
|---|---|
| Model name | `yolo26n-sem` |
| Original file name | `yolo26n-sem_w8a32.tflite` |
| sha256 | `321652ea9ddc5cfd5c9f865673ca35c29acd921c02f300d25aa32d5c09f047d1` |
| Size | 1,748,417 bytes |
| Upstream project | Ultralytics YOLO26 |
| Canonical upstream checkpoint | `yolo26n-sem.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n-sem.pt |
| Canonical checkpoint sha256 | `f3f293cca764de1f93044030d8d5612de9c5ffbf37c9c8ea1b69418b73038999` |
| Bundled artifact source | `ultralytics/yolo-flutter-app` release `v0.7.0` asset `yolo26n-sem_w8a32.tflite`, published with the SHA-256 above |
| Bundled artifact URL | https://github.com/ultralytics/yolo-flutter-app/releases/download/v0.7.0/yolo26n-sem_w8a32.tflite |
| Export recipe | `scripts/export-tflite-models.py` at `ultralytics/yolo-flutter-app@5c589835f436`, with `format=litert`, `quantize=w8a32`, `nms=None`, `imgsz=640`, `batch=1` |
| Model version / release tag | Canonical checkpoint `ultralytics/assets v8.4.0`. Bundled artifact `yolo-flutter-app v0.7.0`, exported by **Ultralytics 8.4.188** |
| Embedded export timestamp | `2026-10-24T22:33:23.249116+02:00` |
| Embedded export metadata | `task=semantic`, `batch=1`, `imgsz=[640,640]`, `quantize=w8a32`, `data=null`, `fraction=1.0`, `end2end=false` |
| Code license | AGPL-3.0 (Ultralytics; the embedded metadata states `AGPL-3.0 License`, and `ultralytics/yolo-flutter-app` is AGPL-3.0) |
| Weights license | AGPL-3.0 (per Ultralytics' position; whether copyleft applies to weights is contested in the industry — this repository takes the strict reading of their claim) |
| Training dataset | Cityscapes (19 trainId classes) |
| Dataset license | 🔴 **NON-COMMERCIAL**. This constraint travels with the weights and is independent of any code license |
| Redistribution | Permitted only subject to **both** layers: AGPL-3.0 obligations **and** Cityscapes' rule that a trained model may be distributed only as an abstract derivative that does not allow recovery of the dataset; commercial use of the dataset or derivative work is not permitted |
| Commercial use | 🔴 **Not permitted** (Cityscapes dataset constraint). The maintainers release this distribution free and permanently non-commercial, which is what allows it to bundle this model. **The Cityscapes terms do not permit commercial use of this model, including selling hardware with it**: a commercial product would be a separate application with a sem model trained on commercially usable data |
| Export format | Ultralytics LiteRT export (`format=litert`: litert-torch + ai-edge-quantizer), `w8a32` (INT8 weights, FP32 activations), NCHW. Chosen over the legacy onnx2tf float16 NHWC export of the same checkpoint, which runs on the LiteRT GPU without an error and computes wrongly there ("Accelerator result consistency" in [`models.md`](../sailens/docs/models.md)) |
| I/O | FLOAT32 `[1,3,640,640]` → FLOAT32 `[1,19,640,640]` dense scores (NCHW) |
| Runtime target | LiteRT 2.3.2, GPU |

## det.tflite

| Field | Value |
|---|---|
| Model name | `yolo26n` |
| Original file name | `yolo26n_w8a32.tflite` |
| sha256 | `15c3726c854de95b3b676aa677f7f57727cb61221012aa741a9cc383c1665e50` |
| Size | 2,875,561 bytes |
| Upstream project | Ultralytics YOLO26 |
| Canonical upstream checkpoint | `yolo26n.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n.pt |
| Canonical checkpoint sha256 | `9b09cc8bf347f0fc8a5f7657480587f25db09b34bf33b0652110fb03a8ad4fef` |
| Bundled artifact source | `ultralytics/yolo-flutter-app` release `v0.7.0` asset `yolo26n_w8a32.tflite`, published with the SHA-256 above |
| Bundled artifact URL | https://github.com/ultralytics/yolo-flutter-app/releases/download/v0.7.0/yolo26n_w8a32.tflite |
| Export recipe | `scripts/export-tflite-models.py` at `ultralytics/yolo-flutter-app@5c589835f436`, with `format=litert`, `quantize=w8a32`, `nms=None`, `imgsz=640`, `batch=1` |
| Model version / release tag | Canonical checkpoint `ultralytics/assets v8.4.0`. Bundled artifact `yolo-flutter-app v0.7.0`, exported by **Ultralytics 8.4.188** |
| Embedded export timestamp | `2026-10-24T22:30:24.588865+02:00` |
| Embedded export metadata | `task=detect`, `batch=1`, `imgsz=[640,640]`, `quantize=w8a32`, `data=null`, `fraction=1.0`, `end2end=false` |
| Code license | AGPL-3.0 (Ultralytics; as for sem) |
| Weights license | AGPL-3.0 (as above) |
| Training dataset | COCO (80 classes) |
| Dataset license | Annotations are CC BY 4.0; images carry their own source terms. ⚠️ **Review before release** |
| Redistribution | Permitted, under AGPL-3.0 |
| Commercial use | Looser than sem (COCO has no non-commercial clause), but **still bound by the AGPL weights** |
| Export format | Ultralytics LiteRT export (`format=litert`: litert-torch + ai-edge-quantizer), `w8a32` (INT8 weights, FP32 activations), NCHW. Chosen over the legacy onnx2tf float16 NHWC export, as for sem |
| I/O | FLOAT32 `[1,3,640,640]` → FLOAT32 `[1,84,8400]` (RAW_TRANSPOSED); boxes in `NORMALIZED` units, the `DetectionModelConfig` default |
| Runtime target | LiteRT 2.3.2, GPU |

## Verification of the bundled files

The checks the "Required steps" below ask for, as they came out for these two files:

| Check | Result |
|---|---|
| Tensor contract (`inspect_tflite.py`) | sem: one FLOAT32 input `[1,3,640,640]`, one FLOAT32 output `[1,19,640,640]`. det: one FLOAT32 input `[1,3,640,640]`, one FLOAT32 output `[1,84,8400]`. Single float output tensors, the contract the zero-copy fast paths need |
| Class order | The embedded names match the established v0.6.6 Cityscapes 19 and COCO 80 orders. The SM8850 recording replay agrees with the v0.6.6 sem argmax on 99.88% of image pixels |
| det box units | The raw centre coordinates and sizes remain in normalized units. Across four fixed CPU inputs, centres are about 0.004–1.04 and sizes reach about 1.03 before clipping |
| Model consistency, OnePlus CPH2747 (SM8850, Android 17), LiteRT 2.3.2 | Passed on 8 live frames. The sem agreement was 97.64% on average and 96.54% on the lowest frame. All 16 CPU boxes matched, with zero extra GPU boxes |
| §12.3 red lines, same device | sem used `native_score` and det used `native_bbox_nms_float_handle`. Both output-read timings were 0 ms, and the trace showed same-frame preprocessing reuse. The distribution's instrumented check matched the handle and array outputs |
| Fixed indoor camera comparison, same device | With the depth lane and debug overlays off, two steady-state windows per arm measured 21.93 decisions/s and 26.90% dropped frames. The LiteRT 2.1.5 and v0.6.6 baseline measured 20.95 decisions/s and 30.18% |
| Recorded-frame comparison, same device | 763 matched det boxes over 813 paired frames. The 575 walking frames had identical qualifications and selected prompts. All 20 selected prompts on 238 image-quality frames matched at the same frame when replayed with the same recorded clock |

## 🔴 The longest pole

**sem's Cityscapes non-commercial constraint is why this distribution is non-commercial, and no
amount of repository splitting changes that** — it travels with the **weights**, not the code
license. The maintainers keep this distribution free and non-commercial. **Selling hardware is unambiguously
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
