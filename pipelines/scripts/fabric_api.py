"""Small authenticated Fabric REST client with throttling and LRO support."""

from __future__ import annotations

import time
from typing import Any

import requests
from azure.identity import AzureCliCredential


class FabricApi:
    def __init__(self) -> None:
        credential = AzureCliCredential()
        token = credential.get_token("https://api.fabric.microsoft.com/.default")
        self.base_url = "https://api.fabric.microsoft.com/v1"
        self.session = requests.Session()
        self.session.headers.update(
            {
                "Authorization": f"Bearer {token.token}",
                "Content-Type": "application/json",
            }
        )

    def request(self, method: str, path_or_url: str, **kwargs: Any) -> requests.Response:
        url = path_or_url if path_or_url.startswith("https://") else f"{self.base_url}{path_or_url}"
        for attempt in range(6):
            response = self.session.request(method, url, timeout=60, **kwargs)
            if response.status_code != 429:
                response.raise_for_status()
                return response
            retry_after = int(response.headers.get("Retry-After", str(2**attempt)))
            time.sleep(min(retry_after, 60))
        raise RuntimeError(f"Fabric API throttling did not clear for {method} {url}")

    def wait_for_lro(self, response: requests.Response) -> None:
        if response.status_code != 202:
            return
        location = response.headers.get("Location")
        if not location:
            raise RuntimeError("Fabric returned 202 without a Location header.")

        while True:
            status_response = self.request("GET", location)
            payload = status_response.json()
            status = str(payload.get("status", "")).lower()
            if status in {"succeeded", "completed"}:
                return
            if status in {"failed", "cancelled", "canceled"}:
                raise RuntimeError(f"Fabric operation failed: {payload}")
            time.sleep(int(status_response.headers.get("Retry-After", "5")))

    def list_all(self, path: str) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        next_url: str | None = path
        while next_url:
            response = self.request("GET", next_url)
            payload = response.json()
            items.extend(payload.get("value", []))
            next_url = payload.get("continuationUri")
        return items
