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

两个文件都是 **Ultralytics 自己发布的 LiteRT 导出**，原样采用。

- **打包文件与官方发布资产的字节一致。** GitHub 的
  [Ultralytics Flutter v0.7.0 资产页](https://github.com/ultralytics/yolo-flutter-app/releases/expanded_assets/v0.7.0)
  列出的两个 SHA-256 值与下表一致。若上游替换资产，仍可用哈希识别本仓库打包的文件。
- **导出参数由上游提供。**
  [v0.7.0 提交中的导出脚本](https://github.com/ultralytics/yolo-flutter-app/blob/5c589835f436d14b74c1d503477c4ad455efe530/scripts/export-tflite-models.py)
  使用 `format=litert`、`quantize=w8a32`、`nms=None` 和 batch 1。这两个资产的输入尺寸是
  640×640，嵌入元数据由 **Ultralytics 8.4.188** 写入，标注 `end2end=false`。
  `w8a32` 使用 INT8 权重和 FP32 激活。
- **上游发布记录未列出转换器的确切依赖版本。** 构建使用已跟踪的上游原始资产，CI 在构建前核对 SHA-256。
- **官方 canonical model identity 按身份对应，不按 hash 绑定。** 内嵌 metadata 标明是在 COCO
  上训练的 YOLO26n 和在 Cityscapes 上训练的 YOLO26n-sem，类别名与契约顺序一致。Ultralytics
  在官方 `ultralytics/assets` `v8.4.0` release 中把这两个 checkpoint 发布为 `yolo26n.pt` 与
  `yolo26n-sem.pt`（URL 与 SHA-256 见下表）。上游脚本按名字加载 checkpoint；TFLite 格式本身
  不会把 source-checkpoint SHA 以可验证方式绑定进产物。

维护者把本发行版作为永久非商用的项目发布（见 [`DISTRIBUTION_NOTICE.zh-CN.md`](../DISTRIBUTION_NOTICE.zh-CN.md)
的定位一节），公开发布即按这个定位接受 Cityscapes 非商用条款。

## sem.tflite

| 项 | 值 |
|---|---|
| 模型名 | `yolo26n-sem` |
| 原始文件名 | `yolo26n-sem_w8a32.tflite` |
| sha256 | `321652ea9ddc5cfd5c9f865673ca35c29acd921c02f300d25aa32d5c09f047d1` |
| 大小 | 1,748,417 字节 |
| 上游项目 | Ultralytics YOLO26 |
| 官方 canonical checkpoint | `yolo26n-sem.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n-sem.pt |
| Canonical checkpoint sha256 | `f3f293cca764de1f93044030d8d5612de9c5ffbf37c9c8ea1b69418b73038999` |
| 打包产物来源 | `ultralytics/yolo-flutter-app` 的 `v0.7.0` 发布资产 `yolo26n-sem_w8a32.tflite` |
| 打包产物 URL | https://github.com/ultralytics/yolo-flutter-app/releases/download/v0.7.0/yolo26n-sem_w8a32.tflite |
| 导出配方 | `ultralytics/yolo-flutter-app@5c589835f436` 的 `scripts/export-tflite-models.py`，参数为 `format=litert`、`quantize=w8a32`、`nms=None`、`imgsz=640`、`batch=1` |
| 模型版本 / release tag | 上游 checkpoint 为 `ultralytics/assets v8.4.0`，打包产物为 `yolo-flutter-app v0.7.0`，由 **Ultralytics 8.4.188** 导出 |
| 内嵌导出时间 | `2026-10-24T22:33:23.249116+02:00` |
| 内嵌导出元数据 | `task=semantic`、`batch=1`、`imgsz=[640,640]`、`quantize=w8a32`、`data=null`、`fraction=1.0`、`end2end=false` |
| 代码 license | AGPL-3.0（Ultralytics；内嵌 metadata 写明 `AGPL-3.0 License`，`ultralytics/yolo-flutter-app` 也是 AGPL-3.0） |
| 权重 license | AGPL-3.0（按 Ultralytics 的主张；权重是否适用 copyleft 在业界有争议，本仓库按其主张从严处理） |
| 训练数据集 | Cityscapes（19 类 trainId） |
| 数据集 license | 🔴 **非商用**。约束跟着权重走，与代码许可无关 |
| 可否再分发 | 仅在**同时**满足两层约束时可：履行 AGPL-3.0 义务；并满足 Cityscapes 条款——trained model 只能作为不能恢复原数据的抽象 derivative 分发，且数据集或 derivative work 不得用于商业目的 |
| 商业使用 | 🔴 **不可**（受 Cityscapes 数据集约束）。维护者把本发行版作为免费、永久非商用的项目发布，正因如此才能打包这个模型。**Cityscapes 条款不允许把这个模型用于商用（含随硬件出售）**：商业产品会是另一个应用，使用在可商用数据上训练的 sem 模型 |
| 导出格式 | Ultralytics LiteRT 导出（`format=litert`：litert-torch + ai-edge-quantizer），`w8a32`（INT8 权重、FP32 激活），NCHW。选它而不选同一 checkpoint 的 legacy onnx2tf float16 NHWC 导出：后者在 LiteRT GPU 上不报错但算错（见 [`models.zh-CN.md`](../sailens/docs/models.zh-CN.md)“加速器结果一致性”） |
| I/O | FLOAT32 `[1,3,640,640]` → FLOAT32 `[1,19,640,640]` 稠密分数（NCHW） |
| 运行目标 | LiteRT 2.3.2，GPU |

## det.tflite

| 项 | 值 |
|---|---|
| 模型名 | `yolo26n` |
| 原始文件名 | `yolo26n_w8a32.tflite` |
| sha256 | `15c3726c854de95b3b676aa677f7f57727cb61221012aa741a9cc383c1665e50` |
| 大小 | 2,875,561 字节 |
| 上游项目 | Ultralytics YOLO26 |
| 官方 canonical checkpoint | `yolo26n.pt` |
| Canonical checkpoint release | `ultralytics/assets` `v8.4.0` |
| Canonical checkpoint URL | https://github.com/ultralytics/assets/releases/download/v8.4.0/yolo26n.pt |
| Canonical checkpoint sha256 | `9b09cc8bf347f0fc8a5f7657480587f25db09b34bf33b0652110fb03a8ad4fef` |
| 打包产物来源 | `ultralytics/yolo-flutter-app` 的 `v0.7.0` 发布资产 `yolo26n_w8a32.tflite` |
| 打包产物 URL | https://github.com/ultralytics/yolo-flutter-app/releases/download/v0.7.0/yolo26n_w8a32.tflite |
| 导出配方 | `ultralytics/yolo-flutter-app@5c589835f436` 的 `scripts/export-tflite-models.py`，参数为 `format=litert`、`quantize=w8a32`、`nms=None`、`imgsz=640`、`batch=1` |
| 模型版本 / release tag | 上游 checkpoint 为 `ultralytics/assets v8.4.0`，打包产物为 `yolo-flutter-app v0.7.0`，由 **Ultralytics 8.4.188** 导出 |
| 内嵌导出时间 | `2026-10-24T22:30:24.588865+02:00` |
| 内嵌导出元数据 | `task=detect`、`batch=1`、`imgsz=[640,640]`、`quantize=w8a32`、`data=null`、`fraction=1.0`、`end2end=false` |
| 代码 license | AGPL-3.0（Ultralytics；同 sem） |
| 权重 license | AGPL-3.0（同上） |
| 训练数据集 | COCO（80 类） |
| 数据集 license | 标注为 CC BY 4.0；图像各自有其来源条款。⚠️ **发布前复核** |
| 可否再分发 | 可，按 AGPL-3.0 |
| 商业使用 | 比 sem 宽松（COCO 无非商用条款），但**仍受 AGPL 权重约束** |
| 导出格式 | Ultralytics LiteRT 导出（`format=litert`：litert-torch + ai-edge-quantizer），`w8a32`（INT8 权重、FP32 激活），NCHW。不选 legacy onnx2tf float16 NHWC 导出，理由同 sem |
| I/O | FLOAT32 `[1,3,640,640]` → FLOAT32 `[1,84,8400]`（RAW_TRANSPOSED）；框坐标是 `NORMALIZED` 单位，即 `DetectionModelConfig` 的默认值 |
| 运行目标 | LiteRT 2.3.2，GPU |

## 打包文件的验证结果

下文“换模型时必须做的事”要求的检查，在这两个文件上的结果：

| 检查 | 结果 |
|---|---|
| 张量契约（`inspect_tflite.py`） | sem：一个 FLOAT32 输入 `[1,3,640,640]`，一个 FLOAT32 输出 `[1,19,640,640]`。det：一个 FLOAT32 输入 `[1,3,640,640]`，一个 FLOAT32 输出 `[1,84,8400]`。都是单个 float 输出张量，即 zero-copy 快速路径要求的契约 |
| 类别顺序 | 内嵌标签与 v0.6.6 的 Cityscapes 19 类、COCO 80 类顺序一致。SM8850 的录像回放与 v0.6.6 的 sem 类别图有 99.88% 的像素一致 |
| det 框单位 | 原始框的中心和宽高仍用归一化单位。四个固定 CPU 输入里，中心坐标约为 0.004–1.04，裁剪前的宽高最大约为 1.03 |
| 模型一致性检查，一加 CPH2747（SM8850，Android 17），LiteRT 2.3.2 | 通过 8 帧实景检查。sem 平均一致率 97.64%，最低单帧 96.54%。GPU 匹配了 CPU 的全部 16 个框，额外框为 0 |
| §12.3 性能红线，同一台手机 | sem 使用 `native_score`，det 使用 `native_bbox_nms_float_handle`。两者的输出读回计时均为 0 ms，trace 中观察到同帧预处理复用。发行版的仪器测试确认 handle 与数组路径输出一致 |
| 同一台手机固定室内机位对照 | 关闭深度车道和诊断叠层，每组两段稳态窗口。新版每秒输出 21.93 个决策，丢帧率 26.90%。LiteRT 2.1.5 和 v0.6.6 基线为 20.95 个决策和 30.18% |
| 同一台手机录像对照 | 813 帧中配对了 763 个检测框。575 帧行走样本的资格判断与主提示一致。按同一录像时钟复核时，238 帧画质样本的 20 条主提示都在同一帧触发 |

## 🔴 最长的那根杆

**sem 的 Cityscapes 非商用约束就是本发行版非商用的原因，换仓库也改变不了**——它跟着**权重**
走，跟代码许可无关。维护者让本发行版保持免费、非商用。**卖硬件是明确商用；商业产品会是另一个应用，使用在
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
