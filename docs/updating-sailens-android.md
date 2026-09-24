**English** | [简体中文](updating-sailens-android.zh-CN.md)

# Updating the Sailens Android submodule

This runbook describes how `wnbotoo/sailens-app` advances its pinned
`wnbotoo/sailens-android` revision.

The `sailens/` directory is a Git submodule. The superproject does not track "whatever is latest"
on a branch; it records one exact Sailens Android commit as a Git gitlink (mode `160000`). That
commit is part of the product build identity and is recorded in Sailens release manifests.

The normal path is a Dependabot pull request. The manual procedure below is the authoritative
fallback and is also useful when a platform bump needs synchronized host-file changes.

## Invariants

Keep these rules true for every bump:

1. `sailens/` must remain a submodule whose URL is
   `https://github.com/wnbotoo/sailens-android.git`.
2. A change merged into `sailens-app/main` must pin a commit that exists on
   `sailens-android/main`.
3. If a Sailens Android PR was **squash-merged**, pin the new post-merge `main` commit, not the
   former PR branch head.
4. The first-party host mirror in `sailens-app/app/src/main` must stay synchronized with the
   reference host in the pinned platform commit, except for explicitly documented
   distribution-specific files.
5. A submodule bump does not itself create a Sailens product release. Product versions and release
   tags belong to `sailens-app`; the exact platform commit becomes part of that release only when
   the product is tagged and released.

Do not merge an app PR that permanently points at an unmerged platform feature branch. It is fine
to use such a pin temporarily for cross-repository review, but re-pin to the final
`sailens-android/main` commit before merging the app PR.

## Default path: Dependabot

The repository currently configures Dependabot with:

```yaml
- package-ecosystem: gitsubmodule
  directory: /
  schedule:
    interval: daily
  open-pull-requests-limit: 1
```

Dependabot is therefore the normal mechanism for noticing a newer submodule revision and opening a
PR. The repository does not enable automatic merge for these PRs.

Treat a Dependabot submodule PR like any other platform integration change:

1. confirm the target commit is on `sailens-android/main`;
2. review the upstream commit range, not only the one-line gitlink change;
3. let `scripts/verify-distribution.py` check the first-party host mirror;
4. resolve any mirror drift intentionally;
5. require the normal `sailens-app` CI to pass before merge.

If the Dependabot PR only changes the gitlink and CI reports mirrored host drift, do **not** bypass
the check. Update the PR with the required host changes when practical, or replace it with a normal
maintenance PR containing both the submodule bump and the synchronized host changes.

## When to use the manual path

Use the manual path when:

- Dependabot has not opened the needed PR yet;
- a specific platform commit must be tested or consumed;
- the bump requires synchronized host-file changes;
- a platform PR was squash-merged and an existing app PR must be re-pinned to the new commit;
- the Dependabot PR is inconvenient to amend;
- you need to reproduce or diagnose the exact gitlink update locally.

## 1. Start from a clean, current app checkout

From the `sailens-app` repository:

```bash
git switch main
git pull --ff-only
git submodule sync --recursive
git submodule update --init --recursive

git status --short
git -C sailens status --short
```

Both status commands should be clean before starting. Do not discard local submodule work just to
perform an update.

Create a maintenance branch:

```bash
git switch -c chore/update-sailens-android
```

Record the currently pinned platform revision:

```bash
OLD_SHA="$(git rev-parse HEAD:sailens)"
echo "old: $OLD_SHA"
```

The same SHA should be reported by:

```bash
git -C sailens rev-parse HEAD
```

If those values differ, realign the working tree before continuing:

```bash
git submodule update --init --recursive
```

## 2. Fetch Sailens Android and choose the target commit

Fetch the platform's current `main`:

```bash
git -C sailens fetch origin main
```

### Update to the current platform main

For the common case:

```bash
NEW_SHA="$(git -C sailens rev-parse origin/main)"
echo "new: $NEW_SHA"
```

### Update to a specific platform main commit

When a particular merged change is required:

```bash
NEW_SHA="<40-character-sailens-android-commit>"
git -C sailens cat-file -e "$NEW_SHA^{commit}"
git -C sailens merge-base --is-ancestor "$NEW_SHA" origin/main
```

The last command must exit successfully. If it does not, the commit is not reachable from the
fetched `sailens-android/main` and must not be used as the permanent app pin.

### Special case: the platform PR was squash-merged

A squash merge creates a **new commit on `main`**. The old feature-branch head is not the commit
that the app should ship.

After the platform PR is merged:

```bash
git -C sailens fetch origin main
NEW_SHA="$(git -C sailens rev-parse origin/main)"
```

If several commits landed on platform `main` after the squash merge, identify the intended merged
commit explicitly and verify it is an ancestor of `origin/main`.

Never copy the pre-merge PR head SHA into `sailens-app/main` merely because it passed review.

## 3. Inspect the platform delta before changing the pin

A submodule update may look like a one-line change in the app repository while representing a large
platform change. Review the actual range first:

```bash
git -C sailens log --oneline --decorate "$OLD_SHA..$NEW_SHA"
git -C sailens diff --stat "$OLD_SHA" "$NEW_SHA"
```

For a deeper review:

```bash
git -C sailens diff "$OLD_SHA" "$NEW_SHA"
```

Pay particular attention to changes affecting:

- the reference host under `app/src/main`;
- DI/composition-root bindings;
- manifest entries and permissions;
- resources used by Guidance/Describe/output;
- ProGuard/R8 rules;
- native/JNI/runtime integration;
- minimum Android/runtime assumptions;
- release-critical behavior or licence boundaries.

A green platform CI run does not remove the need to check the distribution-specific integration
contract in this repository.

## 4. Move the submodule checkout to the target commit

Use a detached checkout because the superproject pins a commit, not a local branch:

```bash
git -C sailens switch --detach "$NEW_SHA"
```

Verify it:

```bash
git -C sailens rev-parse HEAD
git submodule status --recursive
```

Now stage only the gitlink:

```bash
git add sailens
git diff --cached --submodule=log -- sailens
```

The staged diff should show the old and new Sailens Android commits.

Do not use `git submodule update --remote` as the routine maintenance procedure. It hides the
choice of target revision behind branch-tracking configuration; this repository deliberately treats
the exact commit as an explicit, reviewable version boundary.

## 5. Synchronize the first-party host mirror

`sailens-app` intentionally contains a thin first-party host that mirrors the Sailens Android
reference host. Updating the submodule does not automatically update those copied host files.

Run:

```bash
python3 scripts/verify-distribution.py
```

The mirror contract is two-way:

- same-path mirrored files must match byte for byte;
- files added by the platform host must also be added here;
- files removed or renamed by the platform host must also be removed here.

The current intentional differences and exclusions are maintained in
`scripts/verify-distribution.py`:

- `app/src/main/java/com/sailens/app/SailensEdition.kt` — listed in
  `INTENTIONALLY_DIFFERENT` for distribution capability/model choices;
- `app/src/main/res/values/strings.xml` — listed in `INTENTIONALLY_DIFFERENT` for product-specific
  strings;
- `app/src/main/assets/` — listed in `MIRROR_EXCLUDED_DIRS` because the official distribution
  owns bundled model weights.

If verification reports drift, inspect each reported path against the pinned platform copy. For a
normal mirrored file, apply the corresponding platform change in `sailens-app`. For a genuinely
distribution-specific difference, update `INTENTIONALLY_DIFFERENT` only when the difference is an
intentional product contract, not as a shortcut around the check.

Examples:

```bash
diff -u \
  sailens/app/src/main/AndroidManifest.xml \
  app/src/main/AndroidManifest.xml

diff -u \
  sailens/app/proguard-rules.pro \
  app/proguard-rules.pro
```

After synchronizing files:

```bash
git add app scripts/verify-distribution.py
python3 scripts/verify-distribution.py
```

It must pass.

## 6. Run local validation

At minimum:

```bash
python3 scripts/verify-distribution.py
./gradlew build lint --stacktrace
git diff --check
```

Then inspect the complete app change:

```bash
git status
git diff --cached --submodule=log
```

Useful identity checks:

```bash
PINNED_SHA="$(git ls-files --stage sailens | awk '{print $2}')"
CHECKED_OUT_SHA="$(git -C sailens rev-parse HEAD)"

echo "pinned:      $PINNED_SHA"
echo "checked out: $CHECKED_OUT_SHA"

test "$PINNED_SHA" = "$CHECKED_OUT_SHA"
git -C sailens merge-base --is-ancestor "$PINNED_SHA" origin/main
```

The last two commands must succeed.

Local validation is not a substitute for the repository CI. CI additionally exercises the
distribution contract, full Gradle build/lint, release-signing smoke path, shrunk-APK release-string
verification, and release-manifest generation.

## 7. Commit and open the PR

A normal maintenance commit is:

```bash
git commit -m "chore: update Sailens Android submodule"
git push -u origin HEAD
```

Then open a PR:

```bash
gh pr create \
  --base main \
  --title "chore: update Sailens Android submodule" \
  --body "Updates the pinned Sailens Android commit and synchronizes the distribution host as required."
```

The PR description should record:

- old Sailens Android SHA;
- new Sailens Android SHA;
- the platform PR(s) or changes covered by the range;
- any mirrored host files changed in the app;
- any intentional distribution-specific divergence;
- local validation performed.

Do not merge until the normal `sailens-app` CI is green.

## 8. After the app PR merges

Refresh the local checkout:

```bash
git switch main
git pull --ff-only
git submodule update --init --recursive
```

Verify the superproject and submodule agree:

```bash
APP_PIN="$(git rev-parse HEAD:sailens)"
SUBMODULE_HEAD="$(git -C sailens rev-parse HEAD)"

echo "app pin:        $APP_PIN"
echo "submodule HEAD: $SUBMODULE_HEAD"

test "$APP_PIN" = "$SUBMODULE_HEAD"
```

At this point the updated platform revision is part of `sailens-app/main`, but it is **not yet a
public Sailens release**. The product release procedure remains the version-tag and exact-artifact
flow in [`releasing.md`](releasing.md).

## Troubleshooting

### `sailens` shows as modified immediately after pull

The submodule working tree is probably still on the previously checked-out commit:

```bash
git submodule update --init --recursive
```

### The target SHA exists locally but is rejected by the main-ancestry check

Fetch again:

```bash
git -C sailens fetch origin main
```

If the check still fails, the SHA is not on the platform's current `main`. For a squash-merged PR,
use the post-merge commit instead of the feature-branch head.

### `verify-distribution.py` fails after a seemingly harmless bump

Read every mirror diagnostic. Platform host changes can compile in the platform repository while
still requiring a copied manifest/resource/DI/ProGuard change in the official distribution.
The mirror check exists specifically to catch that silent drift.

### The submodule directory has local changes

Do not reset or clean it blindly. Inspect first:

```bash
git -C sailens status
git -C sailens diff
```

Commit/stash intentional platform work in the platform repository, or use a separate clean checkout
for the app bump.

### Dependabot opened a newer bump while another integration PR is in review

Prefer one reviewed platform boundary at a time. Finish or deliberately replace the existing bump
rather than stacking unrelated platform revisions into an app PR without reviewing the expanded
`OLD_SHA..NEW_SHA` range.
