#!/usr/bin/env python3
from __future__ import annotations

import re
import sys

MAX_VERSION_CODE = 2_100_000_000
TAG_PATTERN = re.compile(r"^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")


def resolve(tag: str) -> tuple[str, int]:
    match = TAG_PATTERN.fullmatch(tag)
    if match is None:
        raise ValueError(
            f"Release tag must use vMAJOR.MINOR.PATCH with non-negative integers (got {tag!r})."
        )

    major, minor, patch = (int(value) for value in match.groups())
    if minor > 999 or patch > 999:
        raise ValueError("MINOR and PATCH must each be <= 999 for the Android versionCode mapping.")

    version_code = major * 1_000_000 + minor * 1_000 + patch
    if not 1 <= version_code <= MAX_VERSION_CODE:
        raise ValueError(
            f"Derived Android versionCode {version_code} is outside 1..{MAX_VERSION_CODE}."
        )

    return f"{major}.{minor}.{patch}", version_code


def main() -> int:
    if len(sys.argv) != 2:
        print(f"usage: {sys.argv[0]} vMAJOR.MINOR.PATCH", file=sys.stderr)
        return 2

    try:
        version_name, version_code = resolve(sys.argv[1])
    except ValueError as error:
        print(error, file=sys.stderr)
        return 2

    print(f"version_name={version_name}")
    print(f"version_code={version_code}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
