#!/usr/bin/env python3
"""Select the environment-specific active Fabric Variable Library value set."""

from __future__ import annotations

import argparse

from fabric_api import FabricApi


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace-id", required=True)
    parser.add_argument("--value-set", choices=("DEV", "PROD"), required=True)
    parser.add_argument("--library-name", default="BankingConfig")
    args = parser.parse_args()

    api = FabricApi()
    libraries = api.list_all(f"/workspaces/{args.workspace_id}/variableLibraries")
    matches = [library for library in libraries if library.get("displayName") == args.library_name]
    if len(matches) != 1:
        raise SystemExit(f"Expected one Variable Library named {args.library_name}; found {len(matches)}")

    library = matches[0]
    api.request(
        "PATCH",
        f"/workspaces/{args.workspace_id}/variableLibraries/{library['id']}",
        json={"properties": {"activeValueSetName": args.value_set}},
    )
    print(f"Activated {args.value_set} on {args.library_name} in workspace {args.workspace_id}")


if __name__ == "__main__":
    main()
