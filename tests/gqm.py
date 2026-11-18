"""Offline integration tests: python3 tests/gqm.py (requires ghq and zsh)."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).resolve().parents[1] / "zsh/functions/gqm.zsh"


class GqmTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / "ghq"
        self.root.mkdir()
        self.env = dict(
            os.environ,
            GHQ_ROOT=str(self.root),
            GIT_CONFIG_GLOBAL=str(self.base / "gitconfig"),
            GIT_CONFIG_NOSYSTEM="1",
        )
        (self.base / "gitconfig").write_text("")

    def repo(self, path, remote=None):
        repo = self.root / path
        repo.mkdir(parents=True)
        subprocess.run(["git", "init", "-q", str(repo)], env=self.env, check=True)
        if remote:
            subprocess.run(
                ["git", "-C", str(repo), "remote", "add", "origin", remote],
                env=self.env,
                check=True,
            )
        (repo / "untracked.txt").write_text("keep this file\n")
        return repo

    def run_gqm(self, *args, cwd=None):
        return subprocess.run(
            [
                "zsh",
                "-f",
                "-c",
                'source "$1"; shift; gqm "$@"',
                "test",
                str(SCRIPT),
                *args,
            ],
            cwd=cwd or self.base,
            env=self.env,
            text=True,
            capture_output=True,
        )

    def test_preview_apply_and_second_run(self):
        old = self.repo(
            "old.example/user/repo with space", "https://example.com/user/new.git"
        )
        dest = self.root / "example.com/user/new"
        for args in [(), ("--dry-run",)]:
            result = self.run_gqm(*args)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(str(dest), result.stdout)
            self.assertTrue(old.exists())
            self.assertFalse(dest.exists())
        result = self.run_gqm("--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(old.exists())
        self.assertEqual((dest / "untracked.txt").read_text(), "keep this file\n")
        result = self.run_gqm("--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("unchanged=1", result.stdout)

    def test_collision_and_missing_remote_do_not_hide_other_candidates(self):
        old = self.repo("a.example/u/old", "https://example.com/u/taken.git")
        self.repo("example.com/u/taken", "https://example.com/u/taken.git")
        self.repo("b.example/u/no-remote")
        self.repo("c.example/u/move", "https://example.com/u/moved.git")
        result = self.run_gqm("--apply")
        self.assertEqual(result.returncode, 1)
        self.assertTrue(old.exists())
        self.assertIn("already exists", result.stderr)
        self.assertIn("no-remote", result.stderr)
        self.assertTrue((self.root / "example.com/u/moved/untracked.txt").exists())

    def test_current_directory_is_not_moved(self):
        old = self.repo("old.example/u/repo", "https://example.com/u/new.git")
        result = self.run_gqm("--apply", cwd=old)
        self.assertEqual(result.returncode, 1)
        self.assertTrue(old.exists())
        self.assertIn("cd", result.stderr)

    def test_argument_validation(self):
        self.repo("old.example/u/repo", "https://example.com/u/new.git")
        for args in [("--apply", "--dry-run"), ("--dry-run", "--apply"), ("--typo",)]:
            self.assertEqual(self.run_gqm(*args).returncode, 2)
        self.assertEqual(self.run_gqm("--typo", "--help").returncode, 0)
        self.assertFalse((self.root / "example.com/u/new").exists())

    def test_linked_worktree_is_skipped(self):
        main = self.repo("example.com/u/main", "https://example.com/u/main.git")
        subprocess.run(
            [
                "git",
                "-C",
                str(main),
                "-c",
                "user.name=Test",
                "-c",
                "user.email=test@example.com",
                "commit",
                "-qm",
                "init",
                "--allow-empty",
            ],
            env=self.env,
            check=True,
        )
        linked = self.root / "worktree"
        subprocess.run(
            ["git", "-C", str(main), "worktree", "add", "--detach", str(linked)],
            env=self.env,
            check=True,
            capture_output=True,
        )
        result = self.run_gqm("--apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("skipped=1", result.stdout)
        self.assertTrue((linked / ".git").is_file())

    def test_listing_failure_is_reported(self):
        binary = self.base / "bin"
        binary.mkdir()
        fake = binary / "ghq"
        fake.write_text("#!/bin/sh\nexit 1\n")
        fake.chmod(0o755)
        self.env["PATH"] = str(binary) + os.pathsep + self.env["PATH"]
        self.assertEqual(self.run_gqm().returncode, 1)

    def test_empty_list(self):
        result = self.run_gqm()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("candidates=0", result.stdout)


if __name__ == "__main__":
    unittest.main()
