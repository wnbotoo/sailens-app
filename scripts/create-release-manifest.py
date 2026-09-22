#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import subprocess
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODEL_PATHS = {
    "semantic": ROOT / "app/src/main/assets/sem.tflite",
    "detection": ROOT / "app/src/main/assets/det.tflite",
}


def git(*args: str, cwd: Path = ROOT) -> str:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def model_metadata(path: Path) -> dict[str, object] | None:
    try:
        with zipfile.ZipFile(path) as archive:
            with archive.open("metadata.json") as handle:
                metadata = json.load(handle)
    except (KeyError, OSError, ValueError, zipfile.BadZipFile):
        return None
    return metadata if isinstance(metadata, dict) else None


def submodule_sha() -> str:
    stage = git("ls-files", "--stage", "--", "sailens").split()
    if len(stage) < 4 or stage[0] != "160000":
        raise RuntimeError("sailens is not recorded as a gitlink.")
    return stage[1]


def artifact_record(path: Path) -> dict[str, object]:
    return {
        "file": path.name,
        "sha256": sha256(path),
        "sizeBytes": path.stat().st_size,
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--tag", required=True)
    parser.add_argument("--version-name", required=True)
    parser.add_argument("--version-code", required=True, type=int)
    parser.add_argument("--apk", required=True, type=Path)
    parser.add_argument("--signing-cert-sha256", required=True)
    parser.add_argument("--source-archive", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    apk = args.apk.resolve()
    source_archive = args.source_archive.resolve()
    for path in (apk, source_archive, *MODEL_PATHS.values()):
        if not path.is_file():
            raise FileNotFoundError(path)

    certificate_sha256 = args.signing_cert_sha256.lower().replace(":", "")
    if re.fullmatch(r"[0-9a-f]{64}", certificate_sha256) is None:
        raise ValueError("signing certificate SHA-256 must be exactly 64 hexadecimal characters.")

    platform_gitlink = submodule_sha()
    platform_head = git("rev-parse", "HEAD", cwd=ROOT / "sailens")
    if platform_head != platform_gitlink:
        raise RuntimeError(
            f"sailens checkout does not match gitlink ({platform_head} != {platform_gitlink})."
        )

    models: dict[str, object] = {}
    for role, path in MODEL_PATHS.items():
        record = artifact_record(path)
        record["path"] = path.relative_to(ROOT).as_posix()
        metadata = model_metadata(path)
        if metadata is not None:
            record["embeddedUltralyticsMetadata"] = {
                key: metadata.get(key)
                for key in ("version", "date", "task", "imgsz", "args", "end2end")
            }
        models[role] = record

    manifest = {
        "schemaVersion": 2,
        "product": "Sailens",
        "applicationId": "com.sailens",
        "distributionLicense": "AGPL-3.0",
        "channel": "github",
        "tag": args.tag,
        "versionName": args.version_name,
        "versionCode": args.version_code,
        "source": {
            "repository": os.environ.get("GITHUB_REPOSITORY", "wnbotoo/sailens-app"),
            "commit": git("rev-parse", "HEAD"),
            "platformRepository": "wnbotoo/sailens-android",
            "platformCommit": platform_gitlink,
        },
        "models": models,
        "signing": {
            "certificateSha256": certificate_sha256,
            "purpose": "application-signing",
        },
        "artifacts": {
            "apk": artifact_record(apk),
            "correspondingSourceArchive": artifact_record(source_archive),
        },
        "automation": {
            "githubRunId": os.environ.get("GITHUB_RUN_ID"),
            "githubRunAttempt": os.environ.get("GITHUB_RUN_ATTEMPT"),
        },
    }

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
