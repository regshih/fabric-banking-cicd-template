#!/usr/bin/env python3
"""Deploy Git-managed Fabric item definitions using Microsoft's fabric-cicd library."""

from __future__ import annotations

import argparse
import os
import tempfile
from pathlib import Path

import yaml
from azure.identity import AzureCliCredential
from fabric_cicd import FabricWorkspace, publish_all_items, unpublish_all_orphan_items


DEPLOYMENT_PHASES = [
    ["Lakehouse"],
    ["SQLDatabase", "VariableLibrary", "Notebook"],
    ["DataPipeline", "SemanticModel"],
    ["Report"],
]


def phase_parameter_file(source: Path, item_types: list[str], directory: Path) -> Path:
    """Write a phase-scoped parameter file to avoid irrelevant validation warnings."""
    payload = yaml.safe_load(source.read_text(encoding="utf-8")) or {}
    for section in ("find_replace", "key_value_replace"):
        payload[section] = [
            entry
            for entry in payload.get(section, [])
            if not entry.get("item_type") or entry["item_type"] in item_types
        ]
    target = directory / "parameter.yml"
    target.write_text(yaml.safe_dump(payload, sort_keys=False), encoding="utf-8")
    return target


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--environment", choices=("DEV", "PROD"), required=True)
    parser.add_argument("--workspace-id", default=os.getenv("FABRIC_WORKSPACE_ID"))
    parser.add_argument("--workspace-name", default=os.getenv("FABRIC_WORKSPACE_NAME"))
    parser.add_argument("--repository-directory", type=Path, default=Path("fabric-items"))
    parser.add_argument("--remove-orphans", action="store_true")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    if not args.workspace_id and not args.workspace_name:
        raise SystemExit("Provide --workspace-id, --workspace-name, or the matching environment variable.")

    repository_directory = args.repository_directory.resolve()
    parameter_path = repository_directory / "parameter.yml"

    for phase_number, item_types in enumerate(DEPLOYMENT_PHASES, start=1):
        print(f"Publishing phase {phase_number}/{len(DEPLOYMENT_PHASES)}: {', '.join(item_types)}")
        with tempfile.TemporaryDirectory(prefix="fabric-cicd-") as temp_directory:
            scoped_parameter = phase_parameter_file(parameter_path, item_types, Path(temp_directory))
            kwargs: dict[str, object] = {
                "repository_directory": str(repository_directory),
                "item_type_in_scope": item_types,
                "environment": args.environment,
                "parameter_file_path": str(scoped_parameter),
                "token_credential": AzureCliCredential(),
            }
            if args.workspace_id:
                kwargs["workspace_id"] = args.workspace_id
            else:
                kwargs["workspace_name"] = args.workspace_name

            publish_all_items(FabricWorkspace(**kwargs))

    if args.remove_orphans:
        cleanup_kwargs: dict[str, object] = {
            "repository_directory": str(repository_directory),
            "item_type_in_scope": [item for phase in DEPLOYMENT_PHASES for item in phase],
            "environment": args.environment,
            "parameter_file_path": str(parameter_path),
            "token_credential": AzureCliCredential(),
        }
        if args.workspace_id:
            cleanup_kwargs["workspace_id"] = args.workspace_id
        else:
            cleanup_kwargs["workspace_name"] = args.workspace_name
        unpublish_all_orphan_items(FabricWorkspace(**cleanup_kwargs))


if __name__ == "__main__":
    main()
