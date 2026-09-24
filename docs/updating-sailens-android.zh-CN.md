[English](updating-sailens-android.md) | **简体中文**

# 更新 Sailens Android submodule

本文档说明 `wnbotoo/sailens-app` 如何更新其 pin 的
`wnbotoo/sailens-android` revision。

`sailens/` 是 Git submodule。主仓库并不是跟踪某个 branch 的“最新内容”，而是在 tree 中以
gitlink（mode `160000`）记录一个**精确的 Sailens Android commit**。这个 commit 是产品构建
identity 的一部分，正式发布时也会写入 Sailens release manifest。

正常情况下由 Dependabot 创建更新 PR；下面的手动流程是完整 fallback，也适用于 submodule bump
同时需要同步 host 文件的情况。

## 必须保持的约束

每次 bump 都必须满足：

1. `sailens/` 继续是 submodule，URL 必须保持为
   `https://github.com/wnbotoo/sailens-android.git`。
2. 合入 `sailens-app/main` 的 pin 必须指向一个已经存在于
   `sailens-android/main` 的 commit。
3. 如果 Sailens Android PR 使用 **squash merge**，必须 pin merge 后新生成的
   `main` commit，不能 pin 原 PR branch head。
4. `sailens-app/app/src/main` 中的一方 host mirror 必须与所 pin 平台 commit 中的
   reference host 保持同步，只有明确记录的 distribution-specific 文件可以不同。
5. submodule bump 本身不会创建 Sailens 产品版本。产品版本和 tag 属于 `sailens-app`；只有
   产品真正打 tag 发布时，这个精确 platform commit 才成为该 release identity 的一部分。

不要把一个永久指向“尚未合入的平台 feature branch”的 app PR 合入 `sailens-app/main`。
跨仓库联调/review 时可以临时这样 pin，但 app PR 合入前必须重新 pin 到最终的
`sailens-android/main` commit。

## 默认流程：Dependabot

仓库当前的 Dependabot 配置包含：

```yaml
- package-ecosystem: gitsubmodule
  directory: /
  schedule:
    interval: daily
  open-pull-requests-limit: 1
```

因此，默认由 Dependabot 检查 submodule 更新并创建 PR。当前配置没有开启自动 merge。

处理 Dependabot submodule PR 时，不要把它当成普通的一行 hash 更新。至少要：

1. 确认目标 commit 已经位于 `sailens-android/main`；
2. review 实际的 upstream commit range，而不是只看 gitlink 那一行；
3. 让 `scripts/verify-distribution.py` 检查一方 host mirror；
4. 对发现的 mirror drift 做有意识的同步或豁免；
5. `sailens-app` 正常 CI 全部通过后再 merge。

如果 Dependabot PR 只更新了 gitlink，而 CI 报 host mirror drift，不要绕过检查。如果方便，可以
在该 PR 上补齐 host 改动；如果不方便修改 Dependabot PR，就关闭/替换成一个普通 maintenance
PR，在同一个 PR 里同时完成 submodule bump 和 host 同步。

## 什么情况下走手动流程

以下情况适合手动更新：

- Dependabot 还没有创建需要的 PR；
- 需要测试或消费一个指定的 platform commit；
- submodule bump 同时需要同步 host 文件；
- 平台 PR 已 squash merge，现有 app PR 需要重新 pin 到新的 merge commit；
- Dependabot PR 不方便追加修改；
- 需要在本地复现或诊断精确的 gitlink 更新。

## 1. 从干净、最新的 app checkout 开始

在 `sailens-app` 仓库中执行：

```bash
git switch main
git pull --ff-only
git submodule sync --recursive
git submodule update --init --recursive

git status --short
git -C sailens status --short
```

开始前两个 status 都应该是干净的。不要为了更新 submodule 而直接丢弃 submodule 中尚未处理的
本地改动。

创建 maintenance branch：

```bash
git switch -c chore/update-sailens-android
```

记录当前 pin 的 platform revision：

```bash
OLD_SHA="$(git rev-parse HEAD:sailens)"
echo "old: $OLD_SHA"
```

下面的命令应得到同一个 SHA：

```bash
git -C sailens rev-parse HEAD
```

如果两者不一致，先重新对齐工作区：

```bash
git submodule update --init --recursive
```

## 2. Fetch Sailens Android 并选择目标 commit

先 fetch 当前 platform `main`：

```bash
git -C sailens fetch origin main
```

### 更新到最新 platform main

最常见情况：

```bash
NEW_SHA="$(git -C sailens rev-parse origin/main)"
echo "new: $NEW_SHA"
```

### 更新到指定的 platform main commit

如果只需要消费某个已经 merge 的变更：

```bash
NEW_SHA="<40-character-sailens-android-commit>"
git -C sailens cat-file -e "$NEW_SHA^{commit}"
git -C sailens merge-base --is-ancestor "$NEW_SHA" origin/main
```

最后一条命令必须成功。如果失败，说明这个 commit 不可从当前 fetch 到的
`sailens-android/main` 到达，不能作为 app 的永久 pin。

### 特殊情况：platform PR 是 squash merge

Squash merge 会在 `main` 上创建一个**新的 commit**。原 feature branch head 并不是 app
最终应该发布的 commit。

平台 PR merge 后重新执行：

```bash
git -C sailens fetch origin main
NEW_SHA="$(git -C sailens rev-parse origin/main)"
```

如果 squash merge 后平台 `main` 又合入了其他提交，就明确找到目标 merged commit，并用
`merge-base --is-ancestor` 验证它确实属于当前 `origin/main`。

不要因为 merge 前的 PR head 已经 review/CI 通过，就把那个旧 SHA 直接写进
`sailens-app/main`。

## 3. 改 pin 前先 review platform delta

在 app 仓库里，submodule bump 可能只显示一行变化，但背后可能包含大量 platform 改动。先看真实
range：

```bash
git -C sailens log --oneline --decorate "$OLD_SHA..$NEW_SHA"
git -C sailens diff --stat "$OLD_SHA" "$NEW_SHA"
```

需要更完整 review 时：

```bash
git -C sailens diff "$OLD_SHA" "$NEW_SHA"
```

尤其关注：

- `app/src/main` 下的 reference host；
- DI / composition-root binding；
- manifest 与权限；
- Guidance / Describe / output 使用的 resources；
- ProGuard / R8 规则；
- native / JNI / runtime 集成；
- Android/runtime 最低要求；
- release-critical 行为或 licence boundary。

平台 CI 通过并不代表这个 distribution 仓库的 integration contract 自动成立。

## 4. 把 submodule checkout 移到目标 commit

使用 detached checkout，因为主仓库 pin 的是 commit，而不是本地 branch：

```bash
git -C sailens switch --detach "$NEW_SHA"
```

验证：

```bash
git -C sailens rev-parse HEAD
git submodule status --recursive
```

然后只 stage gitlink：

```bash
git add sailens
git diff --cached --submodule=log -- sailens
```

staged diff 应明确显示旧、新 Sailens Android commit。

日常维护不要直接依赖 `git submodule update --remote`。这个命令会把目标 revision 的选择隐藏在
branch-tracking 配置后面；本仓库刻意把精确 commit 当作显式、可 review 的版本边界。

## 5. 同步一方 host mirror

`sailens-app` 包含一个很薄的一方 host，它会 mirror Sailens Android reference host 的部分文件。
更新 submodule **不会**自动更新这些复制过来的 host 文件。

执行：

```bash
python3 scripts/verify-distribution.py
```

当前 mirror contract 是双向的：

- 两边同路径的 mirrored 文件必须 byte-for-byte 一致；
- platform host 新增的文件，这边也必须新增；
- platform host 删除或 rename 掉的文件，这边也必须删除。

当前允许的差异和排除项由 `scripts/verify-distribution.py` 维护：

- `app/src/main/java/com/sailens/app/SailensEdition.kt`：位于
  `INTENTIONALLY_DIFFERENT`，用于官方发行版的 capability/model 选择；
- `app/src/main/res/values/strings.xml`：位于 `INTENTIONALLY_DIFFERENT`，用于产品专属
  strings；
- `app/src/main/assets/`：位于 `MIRROR_EXCLUDED_DIRS`，因为官方发行版自行打包 model weights。

如果验证报 drift，要逐项对照当前 pin 的 platform 文件。正常 mirror 文件应把对应 platform 修改同步
到 `sailens-app`；只有真正属于 distribution contract 的差异，才应该加入
`INTENTIONALLY_DIFFERENT`。不要把这个集合当成绕过检查的白名单。

例如：

```bash
diff -u \
  sailens/app/src/main/AndroidManifest.xml \
  app/src/main/AndroidManifest.xml

diff -u \
  sailens/app/proguard-rules.pro \
  app/proguard-rules.pro
```

同步后：

```bash
git add app scripts/verify-distribution.py
python3 scripts/verify-distribution.py
```

必须通过。

## 6. 跑本地验证

最低要求：

```bash
python3 scripts/verify-distribution.py
./gradlew build lint --stacktrace
git diff --check
```

然后检查完整 app 改动：

```bash
git status
git diff --cached --submodule=log
```

建议再做一次 identity 校验：

```bash
PINNED_SHA="$(git ls-files --stage sailens | awk '{print $2}')"
CHECKED_OUT_SHA="$(git -C sailens rev-parse HEAD)"

echo "pinned:      $PINNED_SHA"
echo "checked out: $CHECKED_OUT_SHA"

test "$PINNED_SHA" = "$CHECKED_OUT_SHA"
git -C sailens merge-base --is-ancestor "$PINNED_SHA" origin/main
```

最后两条命令必须成功。

本地验证不能代替仓库 CI。CI 还会执行 distribution contract、完整 Gradle build/lint、release signing
smoke path、shrunk APK 的 release string 校验以及 release manifest 生成检查。

## 7. Commit 并创建 PR

正常 maintenance commit：

```bash
git commit -m "chore: update Sailens Android submodule"
git push -u origin HEAD
```

创建 PR：

```bash
gh pr create \
  --base main \
  --title "chore: update Sailens Android submodule" \
  --body "Updates the pinned Sailens Android commit and synchronizes the distribution host as required."
```

PR 描述建议明确记录：

- 旧 Sailens Android SHA；
- 新 Sailens Android SHA；
- 这个 range 覆盖的平台 PR / 变更；
- app 中同步了哪些 mirrored host 文件；
- 是否存在有意保留的 distribution-specific 差异；
- 已执行哪些本地验证。

正常 `sailens-app` CI 全绿前不要 merge。

## 8. App PR merge 后

刷新本地 checkout：

```bash
git switch main
git pull --ff-only
git submodule update --init --recursive
```

确认 superproject 和 submodule 一致：

```bash
APP_PIN="$(git rev-parse HEAD:sailens)"
SUBMODULE_HEAD="$(git -C sailens rev-parse HEAD)"

echo "app pin:        $APP_PIN"
echo "submodule HEAD: $SUBMODULE_HEAD"

test "$APP_PIN" = "$SUBMODULE_HEAD"
```

到这里，新 platform revision 已经成为 `sailens-app/main` 的一部分，但**还不是一个公开 Sailens
release**。产品发布仍然走 [`releasing.md`](releasing.md) 中的版本 tag + exact artifact 流程。

## 常见问题

### pull 之后 `sailens` 立即显示 modified

通常是 submodule 工作区还停在旧 commit：

```bash
git submodule update --init --recursive
```

### 目标 SHA 本地存在，但 main ancestry 校验失败

重新 fetch：

```bash
git -C sailens fetch origin main
```

如果仍然失败，说明这个 SHA 不在当前 platform `main` 上。对于 squash-merged PR，应改用 merge
后生成的 commit，而不是 feature branch head。

### 看起来只是一个很小的 bump，但 `verify-distribution.py` 失败

逐条阅读 mirror diagnostic。Platform host 的 manifest/resource/DI/ProGuard 变化可能在平台仓库里
正常编译，却仍要求官方发行版同步复制。这个检查就是为了捕获这种“能编译但 host 已经漂移”的情况。

### submodule 目录里有本地改动

不要直接 reset/clean。先检查：

```bash
git -C sailens status
git -C sailens diff
```

如果是有效 platform 开发内容，应先在 platform 仓库 commit/stash；或者换一个干净 checkout 来做
app bump。

### 一个 integration PR 还在 review，Dependabot 又发现了更高版本

尽量一次只 review 一个明确 platform boundary。完成当前 bump，或者明确用新 bump 替换旧 bump；
不要在没有重新 review 扩大的 `OLD_SHA..NEW_SHA` range 的情况下，把多个无关 platform revision
顺手叠进同一个 app PR。
