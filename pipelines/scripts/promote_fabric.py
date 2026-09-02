#!/usr/bin/env python3
"""Promote all supported items from Dev Stage to Prod Stage."""

from __future__ import annotations

import argparse

import requests

from fabric_api import FabricApi


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--pipeline-id")
    parser.add_argument("--pipeline-name", default="Fabric Banking Dev-Prod")
    parser.add_argument("--source-stage", default="Dev Stage")
    parser.add_argument("--target-stage", default="Prod Stage")
    parser.add_argument("--note", default="Approved Azure Pipelines promotion")
    args = parser.parse_args()

    api = FabricApi()
    pipeline_id = args.pipeline_id
    if not pipeline_id:
        pipelines = api.list_all("/deploymentPipelines")
        matches = [pipeline for pipeline in pipelines if pipeline.get("displayName") == args.pipeline_name]
        if len(matches) != 1:
            raise SystemExit(f"Expected one deployment pipeline named {args.pipeline_name}; found {len(matches)}")
        pipeline_id = matches[0]["id"]

    pipeline = api.request("GET", f"/deploymentPipelines/{pipeline_id}").json()
    by_name = {stage["displayName"]: stage for stage in pipeline["stages"]}
    if args.source_stage not in by_name or args.target_stage not in by_name:
        raise SystemExit(f"Pipeline stages are {sorted(by_name)}")

    try:
        response = api.request(
            "POST",
            f"/deploymentPipelines/{pipeline_id}/deploy",
            json={
                "sourceStageId": by_name[args.source_stage]["id"],
                "targetStageId": by_name[args.target_stage]["id"],
                "note": args.note,
            },
        )
    except requests.HTTPError as exc:
        payload = exc.response.json() if exc.response is not None else {}
        detail_codes = {
            detail.get("errorCode")
            for detail in payload.get("moreDetails", [])
            if detail.get("errorCode")
        }
        if detail_codes and detail_codes == {"TargetArtifactNameConflict"}:
            print(
                "Fabric deployment-pipeline item pairing is unavailable because target items "
                "with the same names already exist; requesting the approved Git-owned fallback."
            )
            raise SystemExit(3) from exc
        raise
    api.wait_for_lro(response)
    print(f"Promoted {args.source_stage} to {args.target_stage} in pipeline {pipeline_id}")


if __name__ == "__main__":
    main()
