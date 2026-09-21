[English](DISTRIBUTION_NOTICE.md) | **简体中文**

# Sailens 发行版声明

本仓库是 **Sailens 官方 Android 发行版**；按当前打包模型与许可选择，本发行版按
**AGPL-3.0** 分发。

可复用 Android 平台单独维护：

```text
Sailens Android
仓库：https://github.com/wnbotoo/sailens-android
许可：Apache-2.0

Sailens 官方发行版
仓库：https://github.com/wnbotoo/sailens-app
许可：AGPL-3.0
```

本发行版把 Sailens Android 作为 `sailens/` git submodule，通过 Gradle composite build
消费。可复用功能在 Sailens Android 中开发，并通过精确 submodule bump 进入这里。本仓库只负责
薄产品 host、打包模型、产品 identity、capability expectation 与 release material。

## 许可边界

Sailens Android 继续是 Apache-2.0，并且不带任何模型权重。

本发行版当前打包的模型材料及其 provenance/licence 决定了所分发应用按 AGPL-3.0 发布。从本
仓库分发构建物时，需要履行 AGPL-3.0 义务，包括为该精确构建提供完整对应源码；对应源码包含
`sailens/` submodule 所 pin 的精确 Sailens Android commit。

模型文件还各自受上游与训练数据集条款约束。这些义务独立于平台代码许可，不会因为产品统一改名为
Sailens 而消失。

不要把 distribution-specific 或受模型许可覆盖的材料移回 Sailens Android，除非 licence review
确认该变更可以明确按 Apache-2.0 授权。

这是一条项目贡献/复用规则。它本身不限制版权所有者对其拥有相关权利材料的使用；来自其他作者的
贡献仍受适用于这些贡献的权利与许可约束。

## 当前模型 provenance

当前打包模型的完整记录见
[`docs/model-provenance.zh-CN.md`](docs/model-provenance.zh-CN.md)。

当前模型包包含 YOLO 系模型材料，因此：

> **与 Ultralytics 无隶属、未获其背书或赞助。**“YOLO”仅在 model provenance 中用于描述本
> 发行版集成的模型。Ultralytics 的商标（若存在）归其所有者；此处任何内容都不暗示其审阅、
> 批准或背书。

“YOLO”是模型 provenance，不是 Sailens 产品名称。

## 模型记录要求

每个打包模型都必须记录：

```text
1. 模型名称
2. 模型版本
3. 上游项目
4. 下载来源
5. 代码 licence
6. 权重 licence
7. 训练数据集 licence（若已知）
8. 再分发条款
9. 商业使用条款
10. 导出格式与运行时目标
```

## 发布源码要求

从本仓库分发的每个 Sailens 构建物都必须提供：

```text
1. 完整对应源码
2. 构建脚本与构建说明
3. AGPL-3.0 licence 文件
4. 第三方依赖 licence 声明
5. 打包模型的 provenance 与 licence 声明
6. 与发布构建对应的 git tag
7. 该构建使用的精确 Sailens Android submodule commit
```

## 关于页 identity

应用对外显示：

```text
Sailens
License: AGPL-3.0
Source code: https://github.com/wnbotoo/sailens-app
```

模型文件与第三方依赖还可能有额外条款；详见本声明与 model provenance 文档。
