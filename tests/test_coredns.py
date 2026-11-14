"""Run against the packaged CoreDNS with loopback-only upstreams; no public DNS."""

import importlib.util
import os
from pathlib import Path
import socket
import subprocess
import sys
import tempfile
import threading
import time
from types import SimpleNamespace
import unittest

import dns.message
import dns.query
import dns.rcode
import dns.rrset

SOURCE = Path(
    os.environ.get(
        "COREDNS_SOURCE",
        Path(__file__).resolve().parents[1] / "systems/nixos/services/coredns",
    )
)
spec = importlib.util.spec_from_file_location("policy", SOURCE / "generate-policy.py")
policy = importlib.util.module_from_spec(spec)
spec.loader.exec_module(policy)
BINARY = sys.argv.pop(1)


class Upstream:
    def __init__(self):
        self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        self.socket.bind(("127.0.0.1", 0))
        self.port = self.socket.getsockname()[1]
        self.rcode = 0
        self.queries = []
        threading.Thread(target=self.serve, daemon=True).start()

    def serve(self):
        while True:
            data, address = self.socket.recvfrom(65535)
            query = dns.message.from_wire(data)
            question = query.question[0]
            name = str(question.name)
            if name != ".":
                self.queries.append(name)
            if self.rcode is None:
                continue
            reply = dns.message.make_response(query)
            reply.set_rcode(self.rcode)
            if not self.rcode:
                if name.startswith(("cloaked.", "allowed.", "boundary.")):
                    target = (
                        "Sub.Tracker.TEST."
                        if not name.startswith("boundary.")
                        else "nottracker.test."
                    )
                    if name == "cloaked.chain.test.":
                        reply.answer.append(
                            dns.rrset.from_text(
                                name, 1, "IN", "CNAME", "intermediate.test."
                            )
                        )
                        name = "intermediate.test."
                    reply.answer.append(
                        dns.rrset.from_text(name, 1, "IN", "CNAME", target)
                    )
                    name = target
                kind = dns.rdatatype.to_text(question.rdtype)
                values = {
                    "A": "192.0.2.10",
                    "AAAA": "2001:db8::10",
                    "HTTPS": "1 .",
                    "SVCB": "1 .",
                }
                if kind in values:
                    reply.answer.append(
                        dns.rrset.from_text(name, 1, "IN", kind, values[kind])
                    )
            self.socket.sendto(reply.to_wire(), address)


class CoreDNSTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="coredns-test-")
        cls.path = Path(cls.temp.name)
        cls.primary, cls.secondary = Upstream(), Upstream()
        for name, contents in {
            "domains": "ads.test\nchild.ads.test\nblocked.parent.test\n",
            "cnames": "||tracker.test^\n",
            "blocklist": "local.test\n",
            "allowlist": "allowed.ads.test\nallowed.test\n",
        }.items():
            (cls.path / name).write_text(contents)
        cls.args = SimpleNamespace(
            **{
                name: cls.path / name
                for name in ("domains", "cnames", "blocklist", "allowlist")
            },
            output=cls.path,
            protected=["home.test", "tail.test", "invalid"],
        )
        policy.generate(cls.args)
        if "COREDNS_POLICY" in os.environ:
            full = Path(os.environ["COREDNS_POLICY"])
            for name in ("blocked.zone", "cname.conf"):
                contents = (full / name).read_text().splitlines()
                if name == "blocked.zone":
                    contents = contents[3:]  # Keep the fixture's SOA and origin.
                with (cls.path / name).open("a") as output:
                    output.write("\n".join(contents) + "\n")
        with socket.socket() as sock:
            sock.bind(("127.0.0.1", 0))
            cls.port = sock.getsockname()[1]
        values = {
            "tailnetAddress": "127.0.0.1",
            "homeDomain": "home.test",
            "tailDomain": "tail.test",
            "hostName": "test",
            "policy": str(cls.path),
            "zones": str(cls.path / "zones.conf"),
            "forward": str(cls.path / "forward.conf"),
            "cache": str(cls.path / "cache.conf"),
        }
        for name in (
            "Corefile",
            "zones.conf",
            "forward.conf",
            "cache.conf",
            "allowlist.conf",
        ):
            text = (
                (cls.path / name).read_text()
                if name == "allowlist.conf"
                else (SOURCE / name).read_text()
            )
            for key, value in values.items():
                text = text.replace(f"@{key}@", value)
            text = text.replace(":53", f":{cls.port}").replace(
                "127.0.0.1 127.0.0.1", "127.0.0.1"
            )
            text = text.replace("prometheus 127.0.0.1:9153", "")
            text = text.replace(
                "9.9.9.9 1.1.1.1",
                f"127.0.0.1:{cls.primary.port} 127.0.0.1:{cls.secondary.port}",
            )
            text = text.replace("100.100.100.100", f"127.0.0.1:{cls.primary.port}")
            # Short TTL makes the real serve_stale behavior testable without minutes of waiting.
            text = text.replace("cache 300 {", "cache 300 {\n success 9984 300 0")
            (cls.path / name).write_text(text)
        cls.log = (cls.path / "log").open("w+")
        cls.process = subprocess.Popen(
            [BINARY, "-conf", str(cls.path / "Corefile")],
            stdout=cls.log,
            stderr=subprocess.STDOUT,
        )
        for _ in range(100):
            if cls.process.poll() is not None:
                cls.log.seek(0)
                raise RuntimeError(cls.log.read())
            try:
                dns.query.udp(
                    dns.message.make_query("startup.test", "A"),
                    "127.0.0.1",
                    port=cls.port,
                    timeout=0.1,
                )
                break
            except dns.exception.Timeout:
                time.sleep(0.05)
        else:
            raise RuntimeError("CoreDNS did not become ready")

    @classmethod
    def tearDownClass(cls):
        cls.process.terminate()
        cls.process.wait(timeout=5)
        cls.log.close()
        cls.temp.cleanup()

    def setUp(self):
        self.primary.rcode = self.secondary.rcode = 0

    def query(self, name, kind="A"):
        return dns.query.udp(
            dns.message.make_query(name, kind), "127.0.0.1", port=self.port, timeout=8
        )

    def test_blocked_subtrees_and_types(self):
        for name in (
            "ads.test",
            "child.ads.test",
            "deep.child.ads.test",
            "local.test",
            "tracker.test",
        ):
            for kind in ("A", "AAAA", "HTTPS", "SVCB", "MX", "CNAME"):
                with self.subTest(name=name, kind=kind):
                    before = len(self.primary.queries) + len(self.secondary.queries)
                    response = self.query(name, kind)
                    self.assertEqual(response.rcode(), 0)
                    self.assertFalse(response.answer)
                    self.assertEqual(
                        before, len(self.primary.queries) + len(self.secondary.queries)
                    )

    def test_allowlist_and_unlisted_parents(self):
        for name in (
            "allowed.ads.test",
            "deep.allowed.ads.test",
            "parent.test",
            "notads.test",
            "allowed.test",
        ):
            self.assertTrue(
                any(rr.rdtype == dns.rdatatype.A for rr in self.query(name).answer),
                name,
            )

    def test_cname_cloaking(self):
        for kind in ("A", "AAAA", "HTTPS", "SVCB"):
            response = self.query(f"cloaked.{kind.lower()}.test", kind)
            self.assertFalse(
                any(rr.rdtype in (1, 28, 64, 65) for rr in response.answer), response
            )
            self.assertTrue(
                any("blocked.invalid." in str(rr) for rr in response.answer), response
            )
        self.assertTrue(
            any(rr.rdtype == 1 for rr in self.query("boundary.test").answer)
        )
        self.assertFalse(
            any(rr.rdtype == 1 for rr in self.query("cloaked.chain.test").answer)
        )
        self.assertNotIn("blocked.invalid.", self.primary.queries)

    def test_internal_zones(self):
        self.assertEqual(str(self.query("unifi.home.test").answer[0][0]), "127.0.0.1")
        self.assertFalse(self.query("unifi.home.test", "AAAA").answer)
        self.assertTrue(self.query("host.tail.test").answer)

    def test_upstream_priority_and_failover(self):
        for label, code, secondary, result in (
            ("primary", 0, False, 0),
            ("servfail", 2, True, 0),
            ("refused", 5, True, 0),
            ("nxdomain", 3, False, 3),
            ("timeout", None, True, 0),
            ("recovery", 0, False, 0),
        ):
            self.primary.rcode = code
            if label == "recovery":
                time.sleep(1.2)
            name = f"{label}.failover.test."
            self.assertEqual(self.query(name).rcode(), result, label)
            self.assertIn(name, self.primary.queries, label)
            self.assertEqual(name in self.secondary.queries, secondary, label)

    def test_stale_cache(self):
        name = "stale.test."
        self.assertTrue(self.query(name).answer)
        time.sleep(2.1)
        self.primary.rcode = self.secondary.rcode = 2
        response = self.query(name)
        self.assertEqual(response.rcode(), 0)
        self.assertTrue(response.answer)
        self.assertEqual(response.answer[0].ttl, 0)
        self.assertGreaterEqual(self.primary.queries.count(name), 2)
        self.assertIn(name, self.secondary.queries)

    def test_invalid_policy_fails_build(self):
        original = self.args.blocklist.read_text()
        try:
            for invalid in ("home.test\n", "test\n", "bad domain.test\n"):
                self.args.blocklist.write_text(invalid)
                with self.assertRaises(ValueError):
                    policy.generate(self.args)
        finally:
            self.args.blocklist.write_text(original)


if __name__ == "__main__":
    unittest.main()
