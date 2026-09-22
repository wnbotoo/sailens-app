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

2026-09-22 的发布审计把“记录模型 identity 对应的**官方 canonical checkpoint**”与
“**当前打包的精确导出产物**”明确分开：

- **官方 canonical model identity 已确认。** Ultralytics 在官方 `ultralytics/assets`
  `v8.4.0` release 中发布了 `yolo26n.pt` 与 `yolo26n-sem.pt`；下表记录这些模型
  identity 对应的精确 URL 与 SHA-256。它确认了官方 canonical 权重，但 TFLite 格式本身
  不会把 source-checkpoint SHA 以可验证方式绑定进产物。
- **当前打包产物能确认 exporter。** 两个 TFLite 都包含 Ultralytics 写入的
  `metadata.json`，其中明确记录 **Ultralytics 8.4.52**、导出时间、task、输入尺寸和
  export args；CI 中的 `scripts/verify-distribution.py` 会把这些字段打印出来。
- 当前选用的是 legacy onnx2tf 导出 bundle 中的 `*_float16.tflite` sibling。文件内
  metadata 记录父导出 invocation 为 `int8=true`、`half=false`。Ultralytics 8.4.52
  在这种调用下会要求 onnx2tf 额外生成 integer-quantized artifact，同时仍生成 float
  variants，并把同一份 export metadata 附加到每个生成的 TFLite。因此 metadata 中的
  `int8=true` **不表示**当前选中的 `*_float16.tflite` 使用 INT8 I/O；下表的实际 tensor
  契约仍是当前 artifact 的权威技术记录。
- **历史 transitive exporter 版本没有完整保留。** embedded metadata pin 住了
  Ultralytics 本身，但没有记录 2026-06-03 当时实际安装的 TensorFlow / onnx2tf / ONNX
  具体版本，因此不能承诺用历史工具链 bit-for-bit 重新导出相同 bytes。这个限制不等于
  release build 不可复现：当前精确 TFLite bytes 已由 Git 跟踪，CI 在构建前校验 SHA-256。
- 本次审计检查的公开 `ultralytics/yolo-flutter-app` release assets（包括 `v0.2.0`
  与 `v0.3.5`）中，没有与当前两个 FP16 文件在文件名/hash/大小上精确匹配的资产，因此这些
  release 只能作为背景，**不能写成当前两个精确产物的下载来源**。

未来换模型时，应把完整 export environment pin 住并和新 artifact 一起保存 recipe。当前模型包
公开发布前仍需要接受 Cityscapes 非商用条款，并执行下文的人工语义顺序与真机 runtime gate。

## sem.tflite

| 项 | 值 |
|---|---|
| 模型名 | `yolo26n-sem` |
| 原始文件名 | `yolo26n-sem_float16.tflite` |
| sha256 | `69e240a9b7ba81b83cef1ffc0bac77698a47a37544c7517259b9accd599ab4f5` |
| 上游项目 | Ultralytics YOLO26 |
| 官方 canonical checkpoint | `yolo26n-sem.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n-sem.pt |
| Canonical checkpoint sha256 | `f3f293cca764de1f93044030d8d5612de9c5ffbf37c9c8ea1b69418b73038999` |
| 当前 artifact derivation | Embedded metadata 确认这是 legacy Ultralytics **8.4.52** TFLite export；精确 artifact 已保存在本仓库并由上面的 SHA-256 标识。不声称存在单独的上游 TFLite 下载 URL |
| 模型版本 / release tag | Canonical checkpoint：`ultralytics/assets v8.4.0`；当前 artifact exporter：**Ultralytics 8.4.52** |
| Embedded export 时间 | `2026-06-03T18:04:36.645162` |
| Embedded 父导出参数 | `task=semantic`、`batch=1`、`imgsz=640x640`、`data=cityscapes8.yaml`、`fraction=1.0`、`int8=true`、`half=false`、`nms=false`、`end2end=false` |
| 代码 license | AGPL-3.0（Ultralytics） |
| 权重 license | AGPL-3.0（按 Ultralytics 的主张；权重是否适用 copyleft 在业界有争议，本仓库按其主张从严处理） |
| 训练数据集 | Cityscapes（19 类 trainId） |
| 数据集 license | 🔴 **非商用**。约束跟着权重走，与代码许可无关 |
| 可否再分发 | 仅在**同时**满足两层约束时可：履行 AGPL-3.0 义务；并满足 Cityscapes 条款——trained model 只能作为不能恢复原数据的抽象 derivative 分发，且数据集或 derivative work 不得用于商业目的 |
| 商业使用 | 🔴 **不可**（受 Cityscapes 数据集约束）。免费 app 有"非商用"论点；**任何商业化（含卖硬件）前必须换用可商用数据训练的 sem 模型** |
| 导出格式 | legacy Ultralytics TensorFlow/TFLite 经 onnx2tf 导出；选择 `yolo26n-sem_float16.tflite` sibling，NHWC |
| I/O | FLOAT32 `[1,640,640,3]` → `Identity` FLOAT32 `[1,640,640,19]` 稠密分数 |
| 运行目标 | LiteRT，GPU |

## det.tflite

| 项 | 值 |
|---|---|
| 模型名 | `yolo26n` |
| 原始文件名 | `yolo26n_float16.tflite` |
| sha256 | `5950fac5e1a92adb17ad907b3925943c5c9dd29d59b0cbc1391efb4eb72740cf` |
| 上游项目 | Ultralytics YOLO26 |
| 官方 canonical checkpoint | `yolo26n.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n.pt |
| Canonical checkpoint sha256 | `9b09cc8bf347f0fc8a5f7657480587f25db09b34bf33b0652110fb03a8ad4fef` |
| 当前 artifact derivation | Embedded metadata 确认这是 legacy Ultralytics **8.4.52** TFLite export；精确 artifact 已保存在本仓库并由上面的 SHA-256 标识。不声称存在单独的上游 TFLite 下载 URL |
| 模型版本 / release tag | Canonical checkpoint：`ultralytics/assets v8.4.0`；当前 artifact exporter：**Ultralytics 8.4.52** |
| Embedded export 时间 | `2026-06-03T19:59:11.798570` |
| Embedded 父导出参数 | `task=detect`、`batch=1`、`imgsz=640x640`、`data=coco128.yaml`、`fraction=1.0`、`int8=true`、`half=false`、`nms=false`、`end2end=false` |
| 代码 license | AGPL-3.0（Ultralytics） |
| 权重 license | AGPL-3.0（同上） |
| 训练数据集 | COCO（80 类） |
| 数据集 license | 标注为 CC BY 4.0；图像各自有其来源条款。⚠️ **发布前复核** |
| 可否再分发 | 可，按 AGPL-3.0 |
| 商业使用 | 比 sem 宽松（COCO 无非商用条款），但**仍受 AGPL 权重约束** |
| 导出格式 | legacy Ultralytics TensorFlow/TFLite 经 onnx2tf 导出；选择 `yolo26n_float16.tflite` sibling，NHWC |
| I/O | FLOAT32 `[1,640,640,3]` → `Identity` FLOAT32 `[1,84,8400]`（RAW_TRANSPOSED） |
| 运行目标 | LiteRT，GPU |

## 🔴 最长的那根杆

**sem 的 Cityscapes 非商用约束是本项目商业化路上最硬的一堵墙，且换仓库解决不了**——它跟着**权重**
走，跟代码许可无关。免费分发有"非商用"论点；**卖硬件是明确商用，届时 sem 必须换成用可商用数据
训练的模型**。这与 A/B 分仓无关，别把"A 是 Apache 了"误当成这个问题也解决了。

## 换模型时必须做的事

1. 跑 `py sailens/scripts/inspect_tflite.py <path>` 对照 [`models.zh-CN.md`](../sailens/docs/models.zh-CN.md) 的契约。
2. **人工验证类别顺序的语义**——Sailens Android 的 `SemanticModelPreflight`（sailens-guidance）
   只能校验 output 能否解析、类别数是否等于声明的 taxonomy，**校验不了类别顺序**。顺序错不会
   报错，会静默把"人行道"当"马路"讲给一个看不见的人听。用一张已知场景实测 argmax 结果再谈精度。
3. 更新本文档的全部 10 项（含 sha256）。
4. 构建并启动这个发行版。它声明了 Guidance required，所以 output 解析不了或类别数不对的模型
   会在用户按下开始之前就停在 fatal configuration 屏——这就是现在的契约闸。检查本身由
   Sailens Android 的测试覆盖：在本仓库根目录跑
   `./gradlew :sailens:sailens-guidance:testDebugUnitTest`。
5. 真机复核 Sailens Android 的性能红线（`sailens/docs/architecture.zh-CN.md` §12.3）：
   `sem: postprocessBackend = "native_score"` 且 `outputReadTimeMs ≈ 0`；
   `det: postprocessBackend = "native_bbox_nms_float_handle"`。
   **Sailens Android 没有权重、验不了这几条，只能在这里验。**§12.3 记录了其中哪几条目前成立；那里
   已经记为不成立的，是既有的已知缺口，不是换模型造成的回归。
