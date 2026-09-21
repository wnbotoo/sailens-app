[English](yolo-models.md) | **简体中文**

# 本 Edition 打包的模型：来源与许可

> 本文档满足 `YOLO_EDITION_NOTICE.md` 要求的模型记录项。**不是法律意见**；发布前应由熟悉开源
> 许可证的顾问复核。
>
> 模型的**技术契约**（shape / 布局 / 类别顺序 / 性能红线）见 Core Edition 的 [`models.zh-CN.md`](../sailens/docs/models.zh-CN.md)。
> 本文只讲**这两个权重是什么、从哪来、什么许可**。

## 打包内容

```text
app/src/main/assets/sem.tflite      语义可行走区域分割
app/src/main/assets/det.tflite      障碍物检测
```

Core Edition 的 `.gitignore` 忽略 `app/src/main/assets/*.tflite`——它不带任何权重；这里把它们
当普通文件跟踪。正是这两个文件让这个 edition 成为 AGPL-3.0。

## sem.tflite

| 项 | 值 |
|---|---|
| 模型名 | `yolo26n-sem` |
| 原始文件名 | `yolo26n-sem_float16.tflite` |
| sha256 | `69e240a9b7ba81b83cef1ffc0bac77698a47a37544c7517259b9accd599ab4f5` |
| 上游项目 | Ultralytics YOLO26 |
| 下载来源 | ⚠️ **待补精确 release URL** — 来自 `ultralytics/yolo-flutter-app` releases 的 canonical Android 资产（v0.3.5 release notes 提到 "full YOLO26 semantic segmentation support"；Android 语义资产可追到 v0.2.0 canonical assets） |
| 模型版本 / release tag | ⚠️ **待确认** |
| 代码 license | AGPL-3.0（Ultralytics） |
| 权重 license | AGPL-3.0（按 Ultralytics 的主张；权重是否适用 copyleft 在业界有争议，本仓库按其主张从严处理） |
| 训练数据集 | Cityscapes（19 类 trainId） |
| 数据集 license | 🔴 **非商用**。约束跟着权重走，与代码许可无关 |
| 可否再分发 | 可，按 AGPL-3.0（须提供完整对应源码） |
| 商业使用 | 🔴 **不可**（受 Cityscapes 数据集约束）。免费 app 有"非商用"论点；**任何商业化（含卖硬件）前必须换用可商用数据训练的 sem 模型** |
| 导出格式 | onnx2tf float16 export，NHWC |
| I/O | FLOAT32 `[1,640,640,3]` → `Identity` FLOAT32 `[1,640,640,19]` 稠密分数 |
| 运行目标 | LiteRT，GPU |

## det.tflite

| 项 | 值 |
|---|---|
| 模型名 | `yolo26n` |
| 原始文件名 | `yolo26n_float16.tflite` |
| sha256 | `5950fac5e1a92adb17ad907b3925943c5c9dd29d59b0cbc1391efb4eb72740cf` |
| 上游项目 | Ultralytics YOLO26 |
| 下载来源 | ⚠️ **待补精确 release URL** |
| 模型版本 / release tag | ⚠️ **待确认** |
| 代码 license | AGPL-3.0（Ultralytics） |
| 权重 license | AGPL-3.0（同上） |
| 训练数据集 | COCO（80 类） |
| 数据集 license | 标注为 CC BY 4.0；图像各自有其来源条款。⚠️ **发布前复核** |
| 可否再分发 | 可，按 AGPL-3.0 |
| 商业使用 | 比 sem 宽松（COCO 无非商用条款），但**仍受 AGPL 权重约束** |
| 导出格式 | onnx2tf float16 export，NHWC |
| I/O | FLOAT32 `[1,640,640,3]` → `Identity` FLOAT32 `[1,84,8400]`（RAW_TRANSPOSED） |
| 运行目标 | LiteRT，GPU |

## 🔴 最长的那根杆

**sem 的 Cityscapes 非商用约束是本项目商业化路上最硬的一堵墙，且换仓库解决不了**——它跟着**权重**
走，跟代码许可无关。免费分发有"非商用"论点；**卖硬件是明确商用，届时 sem 必须换成用可商用数据
训练的模型**。这与 A/B 分仓无关，别把"A 是 Apache 了"误当成这个问题也解决了。

## 换模型时必须做的事

1. 跑 `py sailens/scripts/inspect_tflite.py <path>` 对照 [`models.zh-CN.md`](../sailens/docs/models.zh-CN.md) 的契约。
2. **人工验证类别顺序的语义**——Core Edition 的 `SemanticModelPreflight`（sailens-guidance）
   只能校验 output 能否解析、类别数是否等于声明的 taxonomy，**校验不了类别顺序**。顺序错不会
   报错，会静默把"人行道"当"马路"讲给一个看不见的人听。用一张已知场景实测 argmax 结果再谈精度。
3. 更新本文档的全部 10 项（含 sha256）。
4. 构建并启动这个 edition。它声明了 Guidance required，所以 output 解析不了或类别数不对的模型
   会在用户按下开始之前就停在 fatal configuration 屏——这就是现在的契约闸。检查本身由 Core
   Edition 的测试覆盖：在本仓库根目录跑 `./gradlew :sailens:sailens-guidance:testDebugUnitTest`。
5. 真机复核 Core Edition 的性能红线（`sailens/docs/architecture.zh-CN.md` §12.3）：
   `sem: postprocessBackend = "native_score"` 且 `outputReadTimeMs ≈ 0`；
   `det: postprocessBackend = "native_bbox_nms_float_handle"`。
   **Core Edition 没有权重、验不了这几条，只能在这里验。**§12.3 记录了其中哪几条目前成立；那里
   已经记为不成立的，是既有的已知缺口，不是换模型造成的回归。
