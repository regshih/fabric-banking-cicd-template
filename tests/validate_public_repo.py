#!/usr/bin/env python3
"""Fail when public-template hygiene regresses."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
GUID = re.compile(r"(?i)\b[0-9a-f]{8}(?:-[0-9a-f]{4}){3}-[0-9a-f]{12}\b")
PLACEHOLDER_GUIDS = {
    "00000000-0000-0000-0000-000000000000",
    "00000000-0000-0000-0000-000000000001",
    "00000000-0000-0000-0000-000000000002",
    "00000000-0000-0000-0000-000000000003",
    "00000000-0000-0000-0000-000000000004",
    "00000000-0000-0000-0000-000000000005",
    "00000000-0000-0000-0000-000000000006",
}


def fail(messages: list[str]) -> None:
    for message in messages:
        print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    tracked = subprocess.run(
        ["git", "ls-files"], cwd=ROOT, check=True, capture_output=True, text=True
    ).stdout.splitlines()
    errors: list[str] = []

    forbidden_names = re.compile(
        r"(?i)(^|/)(\.env|.*\.tfvars|.*\.tfstate(?:\..*)?|.*\.(?:pem|pfx|key))$"
    )
    for relative in tracked:
        normalized = relative.replace("\\", "/")
        if forbidden_names.search(normalized) and not normalized.endswith(".example"):
            errors.append(f"sensitive filename is tracked: {normalized}")

    if "docs/live-environment.md" in tracked:
        errors.append("completed live-environment.md must remain private; commit only the example")

    review_suffixes = {".md", ".tf", ".yml", ".yaml", ".example"}
    forbidden_markers = (
        "dev.azure" + ".com/",
        "build" + "Id=",
        "-----BEGIN " + "PRIVATE KEY-----",
    )
    for relative in tracked:
        path = ROOT / relative
        if path.suffix.lower() not in review_suffixes or not path.is_file():
            continue
        text = path.read_text(encoding="utf-8")
        for marker in forbidden_markers:
            if marker in text:
                errors.append(f"environment-specific marker {marker!r} in {relative}")
        if path.suffix.lower() in {".md", ".example"}:
            for value in GUID.findall(text):
                if value.lower() not in PLACEHOLDER_GUIDS:
                    errors.append(f"non-placeholder GUID in public surface {relative}")

    if errors:
        fail(sorted(set(errors)))

    print(f"Validated public-repository hygiene across {len(tracked)} tracked files.")


if __name__ == "__main__":
    main()
