"""Real packaged CoreDNS + existing production-policy fixture, no public DNS."""

import os
import subprocess
import time
import unittest
from pathlib import Path
from unittest.mock import patch

import dns.flags
import dns.message
import dns.query
import dns.rdatatype
from test_coredns import BINARY, CoreDNSTest


class DNS64Test(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        CoreDNSTest.setUpClass()
        cls.path = CoreDNSTest.path
        config = (
            Path(os.environ["DNS64_CONFIG"])
            .read_text()
            .replace("127.0.0.1:5353", f"127.0.0.1:{CoreDNSTest.port}")
        )
        (cls.path / "dns64.conf").write_text(config)
        cls.log = (cls.path / "dns64.log").open("w+")
        cls.process = subprocess.Popen(
            [BINARY, "-conf", str(cls.path / "dns64.conf")],
            stdout=cls.log,
            stderr=subprocess.STDOUT,
        )
        for _ in range(100):
            if cls.process.poll() is not None:
                cls.log.seek(0)
                raise RuntimeError(cls.log.read())
            try:
                cls.query("startup.test", "A")
                break
            except dns.exception.Timeout:
                time.sleep(0.05)
        else:
            raise RuntimeError("DNS64 did not start")

    @classmethod
    def tearDownClass(cls):
        cls.process.terminate()
        cls.process.wait(timeout=5)
        cls.log.close()
        CoreDNSTest.tearDownClass()

    @staticmethod
    def query(name, kind="AAAA", port=11053, tcp=False):
        query = dns.message.make_query(name, kind, want_dnssec=True)
        return (dns.query.tcp if tcp else dns.query.udp)(
            query, "127.0.0.1", port=port, timeout=3
        )

    def test_selected_native_aaaa_replaced(self):
        for tcp in (False, True):
            reply = self.query("sub.selected.test", tcp=tcp)
            self.assertEqual(str(reply.answer[-1][0]), "64:ff9b:1:35::c000:20a")
            self.assertLessEqual(reply.answer[-1].ttl, 30)
            self.assertFalse(reply.flags & dns.flags.AD)

    def test_a_https_svcb_any_suppressed(self):
        for kind in ("A", "HTTPS", "SVCB", "ANY"):
            reply = self.query("selected.test", kind)
            self.assertEqual(reply.rcode(), 0)
            self.assertFalse(reply.answer)

    def test_translate_all_and_allow_ipv4(self):
        for port in (11055, 11057):
            reply = self.query("selected.test", port=port)
            self.assertEqual(str(reply.answer[-1][0]), "2001:db8::10")

    def test_global_and_unselected_unchanged(self):
        for name, port in (
            ("selected.test", CoreDNSTest.port),
            ("unselected.test", 11053),
        ):
            self.assertEqual(
                str(self.query(name, port=port).answer[-1][0]), "2001:db8::10"
            )
            self.assertEqual(
                str(self.query(name, "A", port=port).answer[-1][0]), "192.0.2.10"
            )
        self.assertEqual(
            str(self.query("host.home.test", "A").answer[-1][0]), "127.0.0.1"
        )
        self.assertTrue(self.query("host.tail.test", "A").answer)

    def test_synthesis_clears_upstream_ad(self):
        original = dns.message.make_response

        def authenticated(query, *args, **kwargs):
            reply = original(query, *args, **kwargs)
            reply.flags |= dns.flags.AD
            return reply

        with patch("dns.message.make_response", side_effect=authenticated):
            native = self.query("ad.selected.test", port=CoreDNSTest.port)
            self.assertTrue(native.flags & dns.flags.AD)
            translated = self.query("ad.selected.test")
            self.assertFalse(translated.flags & dns.flags.AD)
            self.assertEqual(str(translated.answer[-1][0]), "64:ff9b:1:35::c000:20a")

    def test_nxdomain_preserved(self):
        CoreDNSTest.primary.rcode = CoreDNSTest.secondary.rcode = 3
        try:
            self.assertEqual(self.query("nonexistent.selected.test").rcode(), 3)
        finally:
            CoreDNSTest.primary.rcode = CoreDNSTest.secondary.rcode = 0

    def test_cname_to_external_cdn(self):
        reply = self.query("boundary.selected.test")
        self.assertEqual(reply.answer[0].rdtype, dns.rdatatype.CNAME)
        self.assertEqual(str(reply.answer[-1].name), "nottracker.test.")
        self.assertEqual(str(reply.answer[-1][0]), "64:ff9b:1:35::c000:20a")

    def test_filtering_and_cname_cloaking(self):
        for name in ("ads.test", "cloaked.chain.test"):
            reply = self.query(name)
            self.assertFalse(
                any(rr.rdtype == dns.rdatatype.AAAA for rr in reply.answer)
            )


if __name__ == "__main__":
    unittest.main()
