#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SUBMODULE_PATH = "sailens"
EXPECTED_SUBMODULE_URL = "https://github.com/wnbotoo/sailens-android.git"
MODELS = {
    "sem.tflite": ROOT / "app/src/main/assets/sem.tflite",
    "det.tflite": ROOT / "app/src/main/assets/det.tflite",
}
SIGNING_CERT_PATH = ROOT / "release/app-signing-certificate.sha256"
EXPECTED_SIGNING_CERT_SHA256 = "0d364c8aace36fce5c345b3e88857080c4fb0c8ffc6482d3059ee88abf67e499"


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def run_git(*args: str, cwd: Path = ROOT, check: bool = True) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=check,
        capture_output=True,
        text=True,
    )


def git(*args: str, cwd: Path = ROOT) -> str:
    return run_git(*args, cwd=cwd).stdout.strip()


def require_pattern(errors: list[str], text: str, pattern: str, message: str) -> None:
    if re.search(pattern, text, re.MULTILINE | re.DOTALL) is None:
        errors.append(message)


def declared_sha256(provenance: str, model_name: str) -> str | None:
    section = re.search(
        rf"(?ms)^##\s+{re.escape(model_name)}\s*$"
        rf"(.*?)(?=^##\s+|\Z)",
        provenance,
    )
    if section is None:
        return None

    sha = re.search(
        r"(?mi)^\|\s*sha256\s*\|\s*`?([0-9a-f]{64})`?\s*\|",
        section.group(1),
    )
    return sha.group(1).lower() if sha else None


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def embedded_ultralytics_metadata(path: Path) -> dict[str, object] | None:
    try:
        with zipfile.ZipFile(path) as archive:
            with archive.open("metadata.json") as metadata_file:
                metadata = json.load(metadata_file)
    except (KeyError, OSError, ValueError, zipfile.BadZipFile):
        return None
    return metadata if isinstance(metadata, dict) else None


# The host app here mirrors Sailens Android's reference host file for file: it is the platform's
# composition root, copied because Gradle cannot share an app module. A submodule bump -- Dependabot
# or by hand -- updates the platform but not this copy, and some drift does not fail the build: a
# ProGuard keep rule missing here compiles fine and crashes the release build at launch. So every
# mirrored file must match the pinned platform byte for byte, except the ones that carry this
# distribution's identity.
MIRROR_ROOTS = ("app/src/main", "app/proguard-rules.pro")
MIRROR_EXCLUDED_DIRS = ("app/src/main/assets",)  # the bundled weights; Sailens Android has none
INTENTIONALLY_DIFFERENT = {
    "app/src/main/java/com/sailens/app/SailensEdition.kt",  # what this edition promises
    "app/src/main/res/values/strings.xml",  # product name
}


def mirrored_files(root: Path) -> set[str]:
    files: set[str] = set()
    for entry in MIRROR_ROOTS:
        path = root / entry
        if path.is_file():
            files.add(entry)
        elif path.is_dir():
            for child in path.rglob("*"):
                relative = child.relative_to(root).as_posix()
                if child.is_file() and not relative.startswith(MIRROR_EXCLUDED_DIRS):
                    files.add(relative)
    return files


def check_host_mirror(errors: list[str], platform_root: Path) -> None:
    ours = mirrored_files(ROOT)
    theirs = mirrored_files(platform_root)
    drifted = sorted(
        path for path in (ours & theirs) - INTENTIONALLY_DIFFERENT
        if (ROOT / path).read_bytes() != (platform_root / path).read_bytes()
    )
    missing_here = sorted(theirs - ours - INTENTIONALLY_DIFFERENT)
    for path in drifted:
        errors.append(
            f"{path} differs from the pinned Sailens Android copy; mirror the platform change "
            f"(diff against {SUBMODULE_PATH}/{path}) or, if the difference is deliberate, add it "
            "to INTENTIONALLY_DIFFERENT."
        )
    for path in missing_here:
        errors.append(
            f"Sailens Android added {path} to its host app; mirror it here or add it to "
            "INTENTIONALLY_DIFFERENT."
        )


def main() -> int:
    errors: list[str] = []

    submodule_path = run_git(
        "config",
        "--file",
        ".gitmodules",
        "--get",
        "submodule.sailens.path",
        check=False,
    )
    if submodule_path.returncode != 0 or submodule_path.stdout.strip() != SUBMODULE_PATH:
        errors.append("The Sailens Android submodule path must remain 'sailens'.")

    submodule_url = run_git(
        "config",
        "--file",
        ".gitmodules",
        "--get",
        "submodule.sailens.url",
        check=False,
    )
    if submodule_url.returncode != 0 or submodule_url.stdout.strip() != EXPECTED_SUBMODULE_URL:
        errors.append(f"The sailens submodule must point to {EXPECTED_SUBMODULE_URL}.")

    stage = git("ls-files", "--stage", "--", SUBMODULE_PATH)
    parts = stage.split()
    if len(parts) < 4 or parts[0] != "160000":
        errors.append("sailens must be tracked as a git submodule (mode 160000).")
        gitlink_sha = None
    else:
        gitlink_sha = parts[1]

    submodule_root = ROOT / SUBMODULE_PATH
    if not submodule_root.is_dir():
        errors.append("sailens submodule is not initialized.")
    else:
        inside = run_git(
            "rev-parse",
            "--is-inside-work-tree",
            cwd=submodule_root,
            check=False,
        )
        if inside.returncode != 0 or inside.stdout.strip() != "true":
            errors.append("sailens submodule is not initialized.")
        elif gitlink_sha is not None:
            submodule_head = git("rev-parse", "HEAD", cwd=submodule_root)
            if submodule_head != gitlink_sha:
                errors.append(
                    "sailens submodule HEAD does not match the superproject gitlink "
                    f"({submodule_head} != {gitlink_sha})."
                )
            commit_check = run_git(
                "cat-file",
                "-e",
                f"{submodule_head}^{{commit}}",
                cwd=submodule_root,
                check=False,
            )
            if commit_check.returncode != 0:
                errors.append(f"Submodule HEAD {submodule_head} is not a valid git commit.")
            check_host_mirror(errors, submodule_root)

    settings = read("settings.gradle.kts")
    require_pattern(
        errors,
        settings,
        r'includeBuild\(\s*"sailens"\s*\)',
        'settings.gradle.kts must keep includeBuild("sailens").',
    )
    require_pattern(
        errors,
        settings,
        r'from\(\s*files\(\s*"sailens/gradle/libs\.versions\.toml"\s*\)\s*\)',
        "The distribution must consume the pinned platform version catalog.",
    )

    provenance = read("docs/model-provenance.md")
    for model_name, model_path in MODELS.items():
        relative_path = model_path.relative_to(ROOT).as_posix()
        if not model_path.is_file():
            errors.append(f"Required bundled model is missing: {relative_path}.")
            continue

        tracked = run_git("ls-files", "--error-unmatch", "--", relative_path, check=False)
        if tracked.returncode != 0:
            errors.append(f"Required bundled model is not tracked by git: {relative_path}.")

        declared = declared_sha256(provenance, model_name)
        if declared is None:
            errors.append(f"No 64-character sha256 declaration found for {model_name}.")
            continue

        actual = file_sha256(model_path)
        if actual != declared:
            errors.append(
                f"{model_name} sha256 does not match docs/model-provenance.md "
                f"(actual={actual}, declared={declared})."
            )

    app_gradle = read("app/build.gradle.kts")
    require_pattern(
        errors,
        app_gradle,
        r'applicationId\s*=\s*"com\.sailens"',
        "Official distribution applicationId must remain com.sailens.",
    )
    require_pattern(
        errors,
        app_gradle,
        r'buildConfigField\(\s*"String"\s*,\s*"APP_LICENSE"\s*,\s*"\\"AGPL-3\.0\\""\s*\)',
        "Official distribution APP_LICENSE must remain AGPL-3.0.",
    )
    require_pattern(
        errors,
        app_gradle,
        r'buildConfigField\(\s*"String"\s*,\s*"APP_SOURCE_URL"\s*,\s*'
        r'"\\"https://github\.com/wnbotoo/sailens-app\\""\s*\)',
        "Official distribution APP_SOURCE_URL must point to sailens-app.",
    )

    if not SIGNING_CERT_PATH.is_file():
        errors.append("Pinned app-signing certificate fingerprint is missing.")
    else:
        signing_cert = SIGNING_CERT_PATH.read_text(encoding="utf-8").strip().lower()
        if signing_cert != EXPECTED_SIGNING_CERT_SHA256:
            errors.append(
                "Pinned app-signing certificate fingerprint changed unexpectedly "
                f"({signing_cert} != {EXPECTED_SIGNING_CERT_SHA256})."
            )

    edition = read("app/src/main/java/com/sailens/app/SailensEdition.kt")
    require_pattern(
        errors,
        edition,
        r"guidanceRequired\s*=\s*true",
        "Official distribution must continue to declare Guidance required.",
    )

    if errors:
        print("Sailens distribution contract verification FAILED:", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1

    if gitlink_sha is not None:
        print(f"Sailens Android platform commit: {gitlink_sha}")
    for model_name, model_path in MODELS.items():
        if model_path.is_file():
            print(f"{model_name}: {file_sha256(model_path)}")
            metadata = embedded_ultralytics_metadata(model_path)
            if metadata is None:
                print(f"{model_name} embedded Ultralytics metadata: unavailable")
            else:
                selected_metadata = {
                    key: metadata.get(key)
                    for key in ("version", "date", "task", "imgsz", "args", "end2end")
                }
                print(
                    f"{model_name} embedded Ultralytics metadata: "
                    f"{json.dumps(selected_metadata, sort_keys=True)}"
                )
    print(f"App-signing certificate SHA-256: {EXPECTED_SIGNING_CERT_SHA256}")
    print("Sailens distribution contract verification passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
