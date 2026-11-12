[English](model-provenance.md) | **简体中文**

# 本官方发行版 打包的模型：来源与许可

> 本文档满足 `../DISTRIBUTION_NOTICE.zh-CN.md` 要求的模型记录项。**不是法律意见**；发布前应由熟悉开源
> 许可证的顾问复核。
>
> 模型的**技术契约**（shape / 布局 / 类别顺序 / 性能红线）见 Sailens Android 的 [`models.zh-CN.md`](../sailens/docs/models.zh-CN.md)。
> 本文只讲**这两个权重是什么、从哪来、什么许可**。

## 打包内容

```text
app/src/main/assets/sem.tflite      语义可行走区域分割
app/src/main/assets/det.tflite      障碍物检测
```

Sailens Android 的 `.gitignore` 忽略 `app/src/main/assets/*.tflite`——它不带任何权重；这里把它们
当普通文件跟踪。正是这两个文件让这个发行版成为 AGPL-3.0。

## Provenance 审计状态

两个文件都是 **Ultralytics 自己发布的 LiteRT 导出**，原样采用。审计分开三件事：

- **打包的精确 bytes 就是上游 release asset。** 每个文件都和官方
  `ultralytics/yolo-flutter-app` release `v0.6.6` 中的一个 asset 逐字节相同：GitHub 服务端
  对该 asset 计算的 SHA-256 digest 等于下表记录的 sha256。两个 asset 都在
  `2026-07-23T20:19:03Z` 由 ultralytics/yolo-flutter-app#568 上传，那个 PR 重新导出并替换了
  该 release 的全部 35 个 LiteRT asset。Release asset 可以被替换（#568 本身就是一例），所以
  本仓库所发内容的身份是这里的 sha256，不是 URL。
- **导出配方是上游脚本。** #568 合并提交 `42f141eec748` 中的
  `scripts/export-tflite-models.py` 对每个模型执行
  `YOLO("<model>.pt").export(format="litert", quantize="w8a32", nms=False, end2end=False, imgsz=640, batch=1)`：
  Ultralytics 的 `format=litert` 路径（litert-torch 转换、ai-edge-quantizer），`w8a32` 指 INT8
  权重加 FP32 激活，不需要校准数据。文件内嵌的 `metadata.json` 与此一致：由
  **Ultralytics 8.4.104** 写入，`args.quantize = "w8a32"`；CI 中的
  `scripts/verify-distribution.py` 会把这些字段打印出来。
- **没有记录确切的 transitive exporter 版本。** Ultralytics 8.4.104 的 `export-litert` extra
  只要求 `litert-torch>=0.9.0`、`ai-edge-litert>=2.1.4`、`ai-edge-quantizer>=0.6.0`；文件本身
  （flatbuffer 里没有转换器版本）和上游 release 都没有记录当时装的是哪个版本，因此不能保证
  bit-for-bit 重新导出相同 bytes。这是审计上的限制，不是 release build 不可复现：精确 bytes
  可以从上游下载，已由本仓库 Git 跟踪，CI 在构建前校验 SHA-256。
- **官方 canonical model identity 按身份对应，不按 hash 绑定。** 内嵌 metadata 标明是在 COCO
  上训练的 YOLO26n 和在 Cityscapes 上训练的 YOLO26n-sem，类别名与契约顺序一致。Ultralytics
  在官方 `ultralytics/assets` `v8.4.0` release 中把这两个 checkpoint 发布为 `yolo26n.pt` 与
  `yolo26n-sem.pt`（URL 与 SHA-256 见下表）。上游脚本按名字加载 checkpoint；TFLite 格式本身
  不会把 source-checkpoint SHA 以可验证方式绑定进产物。

本发行版定位为永久非商用（见 [`DISTRIBUTION_NOTICE.zh-CN.md`](../DISTRIBUTION_NOTICE.zh-CN.md)
的定位一节），公开发布即按这个定位接受 Cityscapes 非商用条款。

## sem.tflite

| 项 | 值 |
|---|---|
| 模型名 | `yolo26n-sem` |
| 原始文件名 | `yolo26n-sem_w8a32.tflite` |
| sha256 | `d29dee0289f29be7e1446095e843109cdff7bdddba9bfd2ffd525425fbc5f557` |
| 大小 | 1,748,412 字节 |
| 上游项目 | Ultralytics YOLO26 |
| 官方 canonical checkpoint | `yolo26n-sem.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n-sem.pt |
| Canonical checkpoint sha256 | `f3f293cca764de1f93044030d8d5612de9c5ffbf37c9c8ea1b69418b73038999` |
| 打包产物来源 | `ultralytics/yolo-flutter-app` release `v0.6.6` 的 asset `yolo26n-sem_w8a32.tflite`，`2026-07-23T20:19:03Z` 由 ultralytics/yolo-flutter-app#568 上传；它的 GitHub digest 等于上面的 sha256 |
| 打包产物 URL | https://github.com/ultralytics/yolo-flutter-app/releases/download/v0.6.6/yolo26n-sem_w8a32.tflite |
| 导出配方 | `ultralytics/yolo-flutter-app@42f141eec748` 的 `scripts/export-tflite-models.py`：`format=litert`、`quantize=w8a32`、`nms=False`、`end2end=False`、`imgsz=640`、`batch=1` |
| 模型版本 / release tag | Canonical checkpoint：`ultralytics/assets v8.4.0`；打包产物：`yolo-flutter-app v0.6.6`，由 **Ultralytics 8.4.104** 导出 |
| Embedded export 时间 | `2026-07-23T20:42:42.194490`（导出者本地时间，无时区） |
| Embedded 导出参数 | `task=semantic`、`batch=1`、`imgsz=640x640`、`quantize=w8a32`、`data=null`、`fraction=1.0`、`end2end=false` |
| 代码 license | AGPL-3.0（Ultralytics；内嵌 metadata 写明 `AGPL-3.0 License`，`ultralytics/yolo-flutter-app` 也是 AGPL-3.0） |
| 权重 license | AGPL-3.0（按 Ultralytics 的主张；权重是否适用 copyleft 在业界有争议，本仓库按其主张从严处理） |
| 训练数据集 | Cityscapes（19 类 trainId） |
| 数据集 license | 🔴 **非商用**。约束跟着权重走，与代码许可无关 |
| 可否再分发 | 仅在**同时**满足两层约束时可：履行 AGPL-3.0 义务；并满足 Cityscapes 条款——trained model 只能作为不能恢复原数据的抽象 derivative 分发，且数据集或 derivative work 不得用于商业目的 |
| 商业使用 | 🔴 **不可**（受 Cityscapes 数据集约束）。本发行版免费、永久非商用，正因如此才能打包这个模型。**任何商用（含卖硬件）都不在本仓库的范围内**：商业产品会是另一个应用，使用在可商用数据上训练的 sem 模型 |
| 导出格式 | Ultralytics LiteRT 导出（`format=litert`：litert-torch + ai-edge-quantizer），`w8a32`（INT8 权重、FP32 激活），NCHW。选它而不选同一 checkpoint 的 legacy onnx2tf float16 NHWC 导出：后者在 LiteRT GPU 上不报错但算错（见 [`models.zh-CN.md`](../sailens/docs/models.zh-CN.md)“加速器结果一致性”） |
| I/O | FLOAT32 `[1,3,640,640]` → FLOAT32 `[1,19,640,640]` 稠密分数（NCHW） |
| 运行目标 | LiteRT，GPU |

## det.tflite

| 项 | 值 |
|---|---|
| 模型名 | `yolo26n` |
| 原始文件名 | `yolo26n_w8a32.tflite` |
| sha256 | `d9cef07ce652ccfa9ce58e4ac8a4df98ff037739a9dad20a8afcae21b545df73` |
| 大小 | 2,875,553 字节 |
| 上游项目 | Ultralytics YOLO26 |
| 官方 canonical checkpoint | `yolo26n.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n.pt |
| Canonical checkpoint sha256 | `9b09cc8bf347f0fc8a5f7657480587f25db09b34bf33b0652110fb03a8ad4fef` |
| 打包产物来源 | `ultralytics/yolo-flutter-app` release `v0.6.6` 的 asset `yolo26n_w8a32.tflite`，`2026-07-23T20:19:03Z` 由 ultralytics/yolo-flutter-app#568 上传；它的 GitHub digest 等于上面的 sha256 |
| 打包产物 URL | https://github.com/ultralytics/yolo-flutter-app/releases/download/v0.6.6/yolo26n_w8a32.tflite |
| 导出配方 | `ultralytics/yolo-flutter-app@42f141eec748` 的 `scripts/export-tflite-models.py`：`format=litert`、`quantize=w8a32`、`nms=False`、`end2end=False`、`imgsz=640`、`batch=1` |
| 模型版本 / release tag | Canonical checkpoint：`ultralytics/assets v8.4.0`；打包产物：`yolo-flutter-app v0.6.6`，由 **Ultralytics 8.4.104** 导出 |
| Embedded export 时间 | `2026-07-23T20:40:41.640955`（导出者本地时间，无时区） |
| Embedded 导出参数 | `task=detect`、`batch=1`、`imgsz=640x640`、`quantize=w8a32`、`data=null`、`fraction=1.0`、`end2end=false` |
| 代码 license | AGPL-3.0（Ultralytics；同 sem） |
| 权重 license | AGPL-3.0（同上） |
| 训练数据集 | COCO（80 类） |
| 数据集 license | 标注为 CC BY 4.0；图像各自有其来源条款。⚠️ **发布前复核** |
| 可否再分发 | 可，按 AGPL-3.0 |
| 商业使用 | 比 sem 宽松（COCO 无非商用条款），但**仍受 AGPL 权重约束** |
| 导出格式 | Ultralytics LiteRT 导出（`format=litert`：litert-torch + ai-edge-quantizer），`w8a32`（INT8 权重、FP32 激活），NCHW。不选 legacy onnx2tf float16 NHWC 导出，理由同 sem |
| I/O | FLOAT32 `[1,3,640,640]` → FLOAT32 `[1,84,8400]`（RAW_TRANSPOSED）；框坐标是 `NORMALIZED` 单位，即 `DetectionModelConfig` 的默认值 |
| 运行目标 | LiteRT，GPU |

## 打包文件的验证结果

下文“换模型时必须做的事”要求的检查，在这两个文件上的结果：

| 检查 | 结果 |
|---|---|
| 张量契约（`inspect_tflite.py`） | sem：一个 FLOAT32 输入 `[1,3,640,640]`，一个 FLOAT32 输出 `[1,19,640,640]`。det：一个 FLOAT32 输入 `[1,3,640,640]`，一个 FLOAT32 输出 `[1,84,8400]`。都是单个 float 输出张量，即 zero-copy 快速路径要求的契约 |
| sem 类别顺序 | 内嵌 `names` 就是 `CityscapesTaxonomy` 的 19 类，顺序相同。在 CPU 上（LiteRT 2.1.5，x86-64），四个合成输入上的 argmax 与同一 checkpoint 的 legacy float16 导出有 92–100% 的像素一致；通道顺序若被打乱，几乎处处都会不一致 |
| det 类别顺序 | 内嵌 `names` 是 COCO 80 类的顺序；`CocoTaxonomy` 用到的每个 id（person 0 … potted plant 58）标签都对得上 |
| det 框单位 | 在 CPU 上、四个合成输入里，所有 anchor 的中心都在 0.002 到 1.081 之间，宽高都小于 1，所以框是 `NORMALIZED`，即 `DetectionModelConfig` 的默认值；不用改配置 |
| 模型一致性检查，OnePlus CPH2747（SM8850，Android 16），LiteRT 2.1.5 GPU | **PASS**：sem GPU/CPU 像素一致率平均 0.964，最低一帧 0.933；det 召回率 1.0，没有多检（CPU 16 个，GPU 16 个），对着地面、画面里有一把办公椅。第一次画面里没有能检出的物体，结果不确定（sem 0.940 / 0.873；det 7 个对 7 个）。legacy 导出在同一台手机上是 sem 0.391、det 21 个里 GPU 检出 0 个 |
| 已知场景，同一台手机 | debug 包室内 Guidance 31 秒：77% 的帧识别到地面（legacy 导出在 GPU 上是 3%，99% 的帧以 `building` 为主）；检出了人和一把办公椅 |
| §12.3 性能红线，同一次导航 | 全部成立：sem 547 次运行都是 `native_score`，`outputReadTimeMs` 都是 0；det 599 次运行都是 `native_bbox_nms_float_handle`，`outputReadTimeMs` 都是 0；每一帧都有一个模型报告 `shared_native_yuv` |
| 帧耗时，同一次导航 | 比 legacy 导出慢（后者快但算错）：管线中位数 43 ms（p90 58），legacy 是 28 ms（p90 37）；每秒输出 22 帧、丢弃 27% 的相机帧，legacy 是 29 帧、0.3%。差别在 sem：它的后处理要等 GPU 结果，中位数 26 ms，legacy 是 15 ms |

## 🔴 最长的那根杆

**sem 的 Cityscapes 非商用约束就是本发行版非商用的原因，换仓库也改变不了**——它跟着**权重**
走，跟代码许可无关。本发行版免费、一直非商用。**卖硬件是明确商用；商业产品会是另一个应用，使用在
可商用数据上训练的 sem 模型，绝不是本仓库的一次发布**。这与 A/B 分仓无关，别把"A 是 Apache 了"误当成这个问题也解决了。

## 换模型时必须做的事

1. 跑 `py sailens/scripts/inspect_tflite.py <path>` 对照 [`models.zh-CN.md`](../sailens/docs/models.zh-CN.md) 的契约。
2. **人工验证类别顺序的语义**——Sailens Android 的 `SemanticModelPreflight`（sailens-guidance）
   只能校验 output 能否解析、类别数是否等于声明的 taxonomy，**校验不了类别顺序**。顺序错不会
   报错，会静默把"人行道"当"马路"讲给一个看不见的人听。用一张已知场景实测 argmax 结果再谈精度。
3. 更新本文档所有适用的 provenance 字段（包括 bundled-artifact sha256 与 embedded export metadata）。
4. 构建并启动这个发行版。它声明了 Guidance required，所以 output 解析不了或类别数不对的模型
   会在用户按下开始之前就停在 fatal configuration 屏——这就是现在的契约闸。检查本身由
   Sailens Android 的测试覆盖：在本仓库根目录跑
   `./gradlew :sailens:sailens-guidance:testDebugUnitTest`。
5. 真机复核 Sailens Android 的性能红线（`sailens/docs/architecture.zh-CN.md` §12.3）：
   `sem: postprocessBackend = "native_score"` 且 `outputReadTimeMs ≈ 0`；
   `det: postprocessBackend = "native_bbox_nms_float_handle"`。
   **Sailens Android 没有权重、验不了这几条，只能在这里验。**§12.3 记录了其中哪几条目前成立；那里
   已经记为不成立的，是既有的已知缺口，不是换模型造成的回归。
6. 在每台支持的设备上跑 debug 版的**模型一致性检查**（设置 → 诊断）：每个模型在它的加速器上和
   CPU 上各算一遍真实相机帧，按 [`models.zh-CN.md`](../sailens/docs/models.zh-CN.md)“加速器结果一致性”
   一节的门槛判定。模型在 GPU 上不报错，也可能算错；Sailens Android 见过 onnx2tf 的 NHWC 导出在
   SM8850 和 SM8450 上正是这样。换 LiteRT 版本或换支持的设备时也要重跑，不只是换模型。
   **Sailens Android 没有权重，这个发行版自带的模型只能在这里查。**
