#!/usr/bin/env python3
"""Verify required Fabric items and Variable Library state after deployment."""

from __future__ import annotations

import argparse

from fabric_api import FabricApi


EXPECTED = {
    ("BankingLakehouse", "Lakehouse"),
    ("BankingSqlDatabase", "SQLDatabase"),
    ("IngestTransactions", "Notebook"),
    ("BankingIngestion", "DataPipeline"),
    ("BankingModel", "SemanticModel"),
    ("BankingOverview", "Report"),
    ("BankingConfig", "VariableLibrary"),
}


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace-id", required=True)
    parser.add_argument("--expected-value-set", choices=("DEV", "PROD"), required=True)
    args = parser.parse_args()

    api = FabricApi()
    items = api.list_all(f"/workspaces/{args.workspace_id}/items")
    actual = {(item.get("displayName"), item.get("type")) for item in items}
    missing = EXPECTED - actual
    if missing:
        raise SystemExit(f"Missing Fabric items: {sorted(missing)}")

    libraries = api.list_all(f"/workspaces/{args.workspace_id}/variableLibraries")
    library = next(item for item in libraries if item.get("displayName") == "BankingConfig")
    details = api.request(
        "GET", f"/workspaces/{args.workspace_id}/variableLibraries/{library['id']}"
    ).json()
    active = details.get("properties", {}).get("activeValueSetName")
    if active != args.expected_value_set:
        raise SystemExit(f"BankingConfig active value set is {active!r}, expected {args.expected_value_set!r}")

    print(f"Verified {len(EXPECTED)} Fabric items and active value set {active}.")


if __name__ == "__main__":
    main()
