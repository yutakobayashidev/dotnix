"""Reconcile the MCP API settings not supported by the Pocket ID provider."""

import argparse
import json
import os
import sys
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen


def request(method, path, data=None):
    body = None if data is None else json.dumps(data).encode()
    req = Request(
        "https://id.yutakobayashi.com/api" + path,
        data=body,
        method=method,
        headers={
            "X-API-Key": os.environ["POCKETID_API_TOKEN"],
            "Content-Type": "application/json",
            "User-Agent": "dotnix-pocket-id-mcp",
        },
    )
    with urlopen(req, timeout=30) as response:
        return json.load(response)


def list_items(call, path, **query):
    page = 1
    items = []
    while True:
        params = urlencode({**query, "pagination[page]": page})
        result = call("GET", path + "?" + params)
        items.extend(result["data"])
        if page >= result["pagination"]["totalPages"]:
            break
        page += 1
    return items


def find_api(call, resource):
    matches = [
        api
        for api in list_items(call, "/apis", search=resource)
        if api["resource"] == resource
    ]
    if len(matches) > 1:
        raise ValueError("Multiple APIs have the configured resource identifier")
    return matches[0] if matches else None


def permissions(api):
    return sorted(
        (
            {
                "key": item["key"],
                "name": item["name"],
                "description": item.get("description") or "",
            }
            for item in api["permissions"]
        ),
        key=lambda item: item["key"],
    )


def differences(api, desired):
    if api is None:
        return ["create API, permissions, and CIMD access"]
    changes = []
    if api["name"] != desired["name"]:
        changes.append("update API name")
    if permissions(api) != permissions(desired):
        changes.append("replace API permissions")
    granted = sorted(
        item["key"] for item in api["permissions"] if item["allowedForCimdClients"]
    )
    if api["allowCimdClients"] != bool(desired["cimdPermissions"]) or granted != sorted(
        desired["cimdPermissions"]
    ):
        changes.append("update CIMD access")
    return changes


def client_grant(api, scopes):
    ids = {item["key"]: item["id"] for item in api["permissions"]}
    if not set(scopes) <= ids.keys():
        return None  # A permission to be created by this apply has no ID yet.
    return {
        "userDelegatedAccess": bool(scopes),
        "clientAccess": False,
        "userDelegatedPermissionIds": sorted(ids[key] for key in scopes),
        "clientPermissionIds": [],
    }


def client_differences(call, api, desired):
    clients = (
        {}
        if api is None
        else {
            item["client"]["id"]: item
            for item in list_items(call, "/apis/" + api["id"] + "/clients")
        }
    )
    changes = []
    for client, scopes in desired["clientPermissions"].items():
        expected = None if api is None else client_grant(api, scopes)
        actual = clients.get(
            client,
            {
                "userDelegatedAccess": False,
                "clientAccess": False,
                "userDelegatedPermissionIds": [],
                "clientPermissionIds": [],
            },
        )
        if expected is None or any(
            (sorted(actual[key]) if isinstance(value, list) else actual[key]) != value
            for key, value in expected.items()
        ):
            changes.append(client)
    return changes


def reconcile(call, desired, apply=False):
    keys = [item["key"] for item in desired["permissions"]]
    grants = [desired["cimdPermissions"], *desired["clientPermissions"].values()]
    if len(keys) != len(set(keys)) or any(
        not set(grant) <= set(keys) for grant in grants
    ):
        raise ValueError(
            "Permission keys must be unique and CIMD grants must reference them"
        )
    api = find_api(call, desired["resource"])
    changes = differences(api, desired)
    changes.extend(
        "update client access: " + client
        for client in client_differences(call, api, desired)
    )
    for change in changes:
        print(f"Ori MCP: {change}")
    if not changes:
        print("Ori MCP: no changes")
    if not apply or not changes:
        return changes

    if api is None:
        api = call(
            "POST", "/apis", {"name": desired["name"], "resource": desired["resource"]}
        )
    path = "/apis/" + api["id"]
    if api["name"] != desired["name"]:
        api = call("PUT", path, {"name": desired["name"]})
    if permissions(api) != permissions(desired):
        api = call(
            "PUT", path + "/permissions", {"permissions": desired["permissions"]}
        )
    # Permission IDs are assigned by Pocket ID and preserved when a key remains.
    # Resolve them after updating the permission list, rather than storing IDs.
    if "update CIMD access" in differences(api, desired):
        ids = [
            item["id"]
            for item in api["permissions"]
            if item["key"] in desired["cimdPermissions"]
        ]
        call(
            "PUT",
            path + "/cimd-access",
            {"enabled": bool(desired["cimdPermissions"]), "permissionIds": ids},
        )
    for client in client_differences(call, api, desired):
        call(
            "PUT",
            path + "/clients/" + quote(client, safe=""),
            client_grant(api, desired["clientPermissions"][client]),
        )
    remaining = differences(call("GET", path), desired)
    remaining.extend(
        "client access: " + client for client in client_differences(call, api, desired)
    )
    if remaining:
        raise RuntimeError("MCP API verification failed: " + ", ".join(remaining))
    print("Ori MCP: applied and verified")
    return changes


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=["plan", "apply"])
    args = parser.parse_args()
    if not os.environ.get("POCKETID_API_TOKEN"):
        parser.error("POCKETID_API_TOKEN is required")
    desired = json.loads(Path(__file__).with_name("mcp.json").read_text())
    try:
        reconcile(request, desired, apply=args.mode == "apply")
    except HTTPError as error:
        # Never include response bodies or request headers in CI logs.
        sys.exit(f"Pocket ID API returned HTTP {error.code}")
    except (URLError, ValueError, RuntimeError) as error:
        sys.exit(f"Pocket ID MCP reconciliation failed: {error}")


if __name__ == "__main__":
    main()
