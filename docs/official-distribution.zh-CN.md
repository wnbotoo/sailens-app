[English](official-distribution.md) | **简体中文**

# Sailens 官方 Android 发行版定位

> 状态：**目标已确认，实施有意后置。**当前仓库仍叫 `sailens-yolo`，当前 application identity
> 也仍代表 YOLO Edition。本文档合入后，再用独立变更完成仓库与产品 identity migration。

跨仓库的权威决策见 Sailens Android：
[`sailens/docs/distribution-model.zh-CN.md`](../sailens/docs/distribution-model.zh-CN.md)。

## 1. 产品角色

本仓库是 **Sailens 官方维护的一方 Android 发行版**。

Sailens Android（`wnbotoo/sailens-android`）实现可复用 capability；本仓库负责选择、配置、
打包、验证并把这些 capability 作为面向最终用户的产品发布。

未来应用商店里的产品名就是：

> **Sailens**

本仓库不是第二个平台，也不是平台 fork，而应一直保持为薄 host。

## 2. 目标 identity

| 项目 | 当前 | 已确认目标 |
|---|---|---|
| 仓库 | `wnbotoo/sailens-yolo` | `wnbotoo/sailens-app` |
| 产品名 | Sailens YOLO Edition | **Sailens** |
| Android namespace | `com.sailens` | `com.sailens` |
| applicationId | `com.sailens.yolo` | `com.sailens` |
| 平台依赖 | `sailens-android` submodule | 不变 |
| 消费方式 | Gradle composite build | 不变 |
| 当前 licence | AGPL-3.0 | 不因 branding 改名而改变 |

仓库采用**原地 rename**，不删除重建，也不再次 fresh-root。

namespace 继续是 `com.sailens`；产品 identity 变化不需要移动 Kotlin package。

## 3. 本仓库负责什么

官方发行版负责产品选择与 release material：

- 薄 Android host 与一方官方 application identity；
- 官方打包模型；
- 模型 hash、provenance、attribution、licence 记录；
- 官方 release 承诺哪些 Sailens capability 必须可用；
- 官方支持/默认的 runtime 与 perception 配置；
- release signing 与 release channel 配置；
- 产品图标/名称、商店 metadata，以及 distribution-specific privacy/release 配置；
- release tag 与 release notes。

当前发行版声明 Guidance required。因此官方打包的 Guidance model 缺失或不兼容时，就是坏掉的
distribution，必须在 static configuration validation 阶段失败，而不是像零模型 reference host
那样安静进入 zero-pipeline。

## 4. 哪些东西继续留在 Sailens Android

可复用实现归 Sailens Android：

- camera/runtime/vision infrastructure；
- Guidance 与 Describe capability implementation；
- shared output/accessibility mechanism；
- reusable shell；
- generic model/runtime abstraction；
- native code 与 reusable tests。

如果本仓库需要的是一般 Sailens consumer 都可复用的行为，应经过 licence review 后在 Sailens
Android 实现，再通过 submodule bump 进入这里。不要让官方 App 长出一份平行平台代码。

## 5. YOLO 降级为 provenance，不再是产品 branding

当前仓库名与产品名包含 “YOLO”，因为这个发行版最初围绕所打包模型来定义。

新定位下，model architecture 是 implementation/provenance detail，而不是产品 identity。
migration 完成后：

- 用户看到的是 **Sailens**，不是 “YOLO Edition”；
- YOLO/Ultralytics 名称继续存在于 model provenance、attribution、compatibility 与 licence 记录；
- 当前 `YOLO_EDITION_NOTICE*` 的内容会被重新组织成 model/distribution notice，而不是删除；
- “YOLO” 从产品名消失，不会消除打包模型带来的任何义务。

这样未来官方 model bundle 更换时，不需要连产品一起改名。

## 6. Source dependency 与版本边界

本仓库继续从源码消费 Sailens Android：

```text
sailens-app
├── app/
├── app/src/main/assets/
└── sailens/ -> wnbotoo/sailens-android @ 精确 main SHA
```

`settings.gradle.kts` 继续：

```kotlin
includeBuild("sailens")
```

当前阶段不发布 Maven。一个 app release 所 pin 的 Sailens Android commit，就是这个 release 的
平台版本边界。

产品 release 应记录：

```text
Sailens v1.x.y
├── Sailens Android @ <main SHA>
├── semantic model @ <version/hash/provenance>
├── detection model @ <version/hash/provenance>
└── official product configuration
```

产品版本/tag 由本仓库负责。为了这种关系，Sailens Android 不需要 Maven artifact version。

## 7. Licence boundary

Sailens Android 继续是 Apache-2.0、零权重。

官方发行版当前继续是 AGPL-3.0，因为它打包的模型及相关许可选择如此。产品改名不会削弱或移除
这些义务；当前 model provenance 文档仍是 release-critical material。

如果未来官方 model bundle 改变，可以在适当法律审查下单独重新评估 distribution licence。

## 8. 后续实施计划

本文档合入后，独立的 positioning change 会：

1. 仓库原地从 `sailens-yolo` rename 为 `sailens-app`；
2. `applicationId` 从 `com.sailens.yolo` 改为 `com.sailens`；
3. namespace 保持 `com.sailens`；
4. 用户可见产品名改为 **Sailens**；
5. 更新 `APP_SOURCE_URL`、About identity 与 identity tests；
6. 把 YOLO Edition notice 重命名/改写为 model provenance/distribution notice；
7. 更新 README/AGENTS/build/release/store 中的仓库与产品 identity；
8. 验证 debug/release build 和真机安装；
9. 在 Sailens Android reference host 改成 `com.sailens.reference` 后，验证两者可并存安装。

这次 migration 不需要再改平台 architecture。
