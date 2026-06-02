import pytest


class TestMarkdownStripping:
    def test_images_removed(self, core_module):
        assert core_module._strip_inline_markdown("![alt](img.png)") == ""

    def test_link_label_kept(self, core_module):
        r = core_module._strip_inline_markdown("[label](http://example.com)")
        assert r == "label"

    def test_bold(self, core_module):
        assert core_module._strip_inline_markdown("**bold**") == "bold"

    def test_italic(self, core_module):
        assert core_module._strip_inline_markdown("*italic*") == "italic"

    def test_inline_code(self, core_module):
        assert core_module._strip_inline_markdown("`code`") == "code"

    def test_heading_marker(self, core_module):
        assert core_module._strip_inline_markdown("# heading") == "heading"

    def test_blockquote_marker(self, core_module):
        assert core_module._strip_inline_markdown("> quote") == "quote"


class TestUrlStripping:
    def test_bare_url_removed(self, core_module):
        t = "see https://example.com page"
        r = core_module._strip_inline_markdown(t)
        assert "example" not in r
        assert "see" in r and "page" in r


class TestInlinePeriod:
    @pytest.mark.parametrize(
        "input_text,expected",
        [
            ("say.sh", "say sh"),
            ("src/foo.tsx", "src/foo tsx"),
            ("0.7.3", "0 7 3"),
            ("127.0.0.1", "127 0 0 1"),
        ],
    )
    def test_inline_period_becomes_space(self, core_module, input_text, expected):
        assert core_module._strip_inline_markdown(input_text) == expected

    def test_sentence_period_preserved(self, core_module):
        t = "Hello world. Next."
        r = core_module._strip_inline_markdown(t)
        assert r == "Hello world. Next."


class TestLeadingBangSigil:
    @pytest.mark.parametrize(
        "input_text,expected",
        [
            ("MR !107", "MR 107"),
            ("!1234", "1234"),
            ("Done!", "Done!"),
            ("Wait!", "Wait!"),
        ],
    )
    def test_bang_sigil_stripped(self, core_module, input_text, expected):
        assert core_module._strip_inline_markdown(input_text) == expected


class TestDashRuns:
    def test_long_dash_collapsed(self, core_module):
        t = "text ——— more"
        r = core_module._strip_inline_markdown(t)
        assert "——" not in r

    def test_single_dash_preserved(self, core_module):
        t = "text — more"
        r = core_module._strip_inline_markdown(t)
        assert "—" in r
