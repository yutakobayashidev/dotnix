import copy
import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location(
    "sync_mcp", Path(__file__).with_name("sync-mcp.py")
)
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)

DESIRED = {
    "name": "Ori MCP",
    "resource": "https://example.com/mcp",
    "permissions": [{"key": "ori:mcp", "name": "Use Ori", "description": "Workspace"}],
    "cimdPermissions": ["ori:mcp"],
    "clientPermissions": {},
}


class FakeAPI:
    def __init__(self):
        self.api = None
        self.writes = []
        self.clients = {}

    def __call__(self, method, path, data=None):
        if method == "GET":
            if "/clients?" in path:
                return {
                    "data": list(copy.deepcopy(self.clients).values()),
                    "pagination": {"totalPages": 1},
                }
            if path.startswith("/apis?"):
                return {
                    "data": [copy.deepcopy(self.api)] if self.api else [],
                    "pagination": {"totalPages": 1},
                }
            return copy.deepcopy(self.api)
        self.writes.append((method, path, data))
        if method == "POST":
            self.api = {
                **data,
                "id": "api-id",
                "permissions": [],
                "allowCimdClients": False,
            }
        elif "/clients/" in path:
            client = path.rsplit("/", 1)[1]
            self.clients[client] = {"client": {"id": client}, **data}
        elif path.endswith("/permissions"):
            old = {p["key"]: p for p in self.api["permissions"]}
            self.api["permissions"] = [
                {
                    **p,
                    "id": old.get(p["key"], {}).get("id", "id-" + p["key"]),
                    "allowedForCimdClients": old.get(p["key"], {}).get(
                        "allowedForCimdClients", False
                    ),
                }
                for p in data["permissions"]
            ]
        elif path.endswith("/cimd-access"):
            self.api["allowCimdClients"] = data["enabled"]
            for p in self.api["permissions"]:
                p["allowedForCimdClients"] = p["id"] in data["permissionIds"]
        else:
            self.api.update(data)
        return copy.deepcopy(self.api)


class ReconcileTests(unittest.TestCase):
    def test_plan_missing_is_read_only(self):
        api = FakeAPI()
        self.assertTrue(sync.reconcile(api, DESIRED))
        self.assertEqual(api.writes, [])
        self.assertIsNone(api.api)

    def test_first_apply_and_repeated_apply(self):
        api = FakeAPI()
        sync.reconcile(api, DESIRED, apply=True)
        self.assertEqual(len(api.writes), 3)
        api.writes.clear()
        self.assertEqual(sync.reconcile(api, DESIRED, apply=True), [])
        self.assertEqual(api.writes, [])

    def test_detect_and_repair_permission_and_grant_drift(self):
        api = FakeAPI()
        sync.reconcile(api, DESIRED, apply=True)
        api.api["permissions"][0]["name"] = "Changed outside deployment"
        api.api["permissions"][0]["allowedForCimdClients"] = False
        api.api["allowCimdClients"] = False
        api.writes.clear()
        self.assertEqual(len(sync.reconcile(api, DESIRED)), 2)
        self.assertEqual(api.writes, [])
        sync.reconcile(api, DESIRED, apply=True)
        self.assertEqual(len(api.writes), 2)
        self.assertEqual(sync.differences(api.api, DESIRED), [])

    def test_remove_permissions_and_disable_access(self):
        api = FakeAPI()
        sync.reconcile(api, DESIRED, apply=True)
        desired = {**DESIRED, "permissions": [], "cimdPermissions": []}
        sync.reconcile(api, desired, apply=True)
        self.assertEqual(api.api["permissions"], [])
        self.assertFalse(api.api["allowCimdClients"])

    def test_reject_unknown_scope_before_api_call(self):
        api = FakeAPI()
        with self.assertRaises(ValueError):
            sync.reconcile(api, {**DESIRED, "cimdPermissions": ["unknown"]}, apply=True)
        self.assertEqual(api.writes, [])

    def test_static_client_grants_user_delegation_only_and_repairs_escalation(self):
        api = FakeAPI()
        desired = {**DESIRED, "clientPermissions": {"ori-chatgpt": ["ori:mcp"]}}
        sync.reconcile(api, desired, apply=True)
        grant = api.clients["ori-chatgpt"]
        self.assertTrue(grant["userDelegatedAccess"])
        self.assertFalse(grant["clientAccess"])
        self.assertEqual(grant["clientPermissionIds"], [])
        self.assertEqual(grant["userDelegatedPermissionIds"], ["id-ori:mcp"])
        api.writes.clear()
        self.assertEqual(sync.reconcile(api, desired, apply=True), [])
        self.assertEqual(api.writes, [])
        grant["clientAccess"] = True
        grant["clientPermissionIds"] = ["id-ori:mcp"]
        self.assertEqual(
            sync.reconcile(api, desired), ["update client access: ori-chatgpt"]
        )
        self.assertEqual(api.writes, [])
        sync.reconcile(api, desired, apply=True)
        self.assertFalse(api.clients["ori-chatgpt"]["clientAccess"])
        desired["clientPermissions"] = {"ori-chatgpt": []}
        sync.reconcile(api, desired, apply=True)
        self.assertFalse(api.clients["ori-chatgpt"]["userDelegatedAccess"])

    def test_paginated_client_grants_are_all_read(self):
        pages = []

        def call(method, path):
            self.assertEqual(method, "GET")
            pages.append(path)
            return {"data": [len(pages)], "pagination": {"totalPages": 2}}

        self.assertEqual(sync.list_items(call, "/apis/id/clients"), [1, 2])
        self.assertIn("page%5D=2", pages[1])


if __name__ == "__main__":
    unittest.main()
