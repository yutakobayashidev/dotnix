"""Verify the configured infra-info endpoint and queue a Tailscale test event."""

import json
import os
import urllib.error
import urllib.parse
import urllib.request


def request(path, method="GET"):
    req = urllib.request.Request(
        "https://api.tailscale.com/api/v2/" + path,
        method=method,
        headers={"Authorization": "Bearer " + os.environ["TF_VAR_tailscale_api_key"]},
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as response:
            body = response.read()
            return json.loads(body) if body else None
    except urllib.error.HTTPError as error:
        # API response bodies may contain the secret endpoint URL.
        raise SystemExit(f"Tailscale API {method} failed: HTTP {error.code}") from None
    except urllib.error.URLError:
        raise SystemExit("Tailscale API connection failed") from None


def main():
    url = os.environ["TF_VAR_discord_infra_info_webhook_url"]
    endpoints = request("tailnet/-/webhooks")["webhooks"]
    matches = [endpoint for endpoint in endpoints if endpoint["endpointUrl"] == url]
    if len(matches) != 1:
        raise SystemExit(f"Expected one infra-info endpoint; found {len(matches)}")
    endpoint = matches[0]
    expected = {"categoryDeviceMisconfigurations", "categoryTailnetManagement"}
    if endpoint["providerType"] != "discord" or not expected.issubset(
        endpoint["subscriptions"]
    ):
        raise SystemExit("Webhook provider or subscriptions do not match configuration")
    endpoint_id = urllib.parse.quote(endpoint["endpointId"], safe="")
    request(f"webhooks/{endpoint_id}/test", method="POST")
    print(f"Verified Discord infra-info endpoint {endpoint_id}; test event queued.")
    print("Confirm the Tailscale test event arrives in Discord infra-info.")


if __name__ == "__main__":
    main()
