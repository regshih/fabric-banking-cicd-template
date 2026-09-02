#!/usr/bin/env python3
"""Offline structural validation for Terraform-adjacent Fabric source definitions."""

from __future__ import annotations

import json
import re
import sys
import uuid
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]
ITEMS = ROOT / "fabric-items"
REQUIRED = {
    "BankingLakehouse.Lakehouse": "Lakehouse",
    "BankingSqlDatabase.SQLDatabase": "SQLDatabase",
    "IngestTransactions.Notebook": "Notebook",
    "BankingIngestion.DataPipeline": "DataPipeline",
    "BankingModel.SemanticModel": "SemanticModel",
    "BankingOverview.Report": "Report",
    "BankingConfig.VariableLibrary": "VariableLibrary",
}


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    json_paths = list(ITEMS.rglob("*.json"))
    yaml_paths = list(ITEMS.rglob("*.yml")) + list((ROOT / "pipelines").rglob("*.yml"))

    for path in json_paths:
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except json.JSONDecodeError as error:
            fail(f"Invalid JSON in {path.relative_to(ROOT)}: {error}")

    for path in yaml_paths:
        try:
            yaml.safe_load(path.read_text(encoding="utf-8"))
        except yaml.YAMLError as error:
            fail(f"Invalid YAML in {path.relative_to(ROOT)}: {error}")

    logical_ids: set[uuid.UUID] = set()
    for folder_name, expected_type in REQUIRED.items():
        platform_path = ITEMS / folder_name / ".platform"
        if not platform_path.exists():
            fail(f"Missing {platform_path.relative_to(ROOT)}")
        platform = json.loads(platform_path.read_text(encoding="utf-8"))
        actual_type = platform.get("metadata", {}).get("type")
        if actual_type != expected_type:
            fail(f"{folder_name} has type {actual_type!r}; expected {expected_type!r}")
        logical_id = uuid.UUID(platform["config"]["logicalId"])
        if logical_id in logical_ids:
            fail(f"Duplicate logical ID {logical_id}")
        logical_ids.add(logical_id)

    variables_path = ITEMS / "BankingConfig.VariableLibrary" / "variables.json"
    variables = json.loads(variables_path.read_text(encoding="utf-8"))["variables"]
    names = {entry["name"] for entry in variables}
    expected_names = {"SQL_ENDPOINT", "LAKEHOUSE_ID", "ENVIRONMENT"}
    if names != expected_names:
        fail(f"Variable Library names are {sorted(names)}; expected {sorted(expected_names)}")

    settings = json.loads(
        (ITEMS / "BankingConfig.VariableLibrary" / "settings.json").read_text(encoding="utf-8")
    )
    if settings["valueSetsOrder"] != ["DEV", "PROD"]:
        fail("Variable Library valueSetsOrder must be DEV then PROD")

    notebook = (ITEMS / "IngestTransactions.Notebook" / "notebook-content.py").read_text(encoding="utf-8")
    if re.search(r"(?i)(real customer|social security|\bssn\b|account_number\s*=)", notebook):
        fail("Notebook appears to contain prohibited customer/PII fields")

    config = yaml.safe_load((ITEMS / "config.yml").read_text(encoding="utf-8"))
    configured_types = set(config["core"]["item_types_in_scope"])
    if configured_types != set(REQUIRED.values()):
        fail("fabric-items/config.yml does not cover every required item type")

    print(f"Validated {len(json_paths)} JSON files, {len(yaml_paths)} YAML files, and {len(REQUIRED)} Fabric items.")


if __name__ == "__main__":
    main()
