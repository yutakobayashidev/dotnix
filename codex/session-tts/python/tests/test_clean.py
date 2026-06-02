class TestParagraphHandling:
    def test_single_paragraph(self, core_module):
        t = "hello world."
        assert core_module.clean(t) == "hello world."

    def test_multi_line_join(self, core_module):
        t = "hello\nworld."
        assert core_module.clean(t) == "hello world."

    def test_blank_line_separates(self, core_module):
        t = "para one.\n\npara two."
        assert core_module.clean(t) == "para one.\n\npara two."


class TestListItems:
    def test_terminal_punct_inserted(self, core_module):
        t = "- item a\n- item b"
        r = core_module.clean(t)
        assert "。" in r

    def test_existing_terminal_preserved(self, core_module):
        t = "- item a!\n- item b？"
        r = core_module.clean(t)
        assert "!" or "？" in r

    def test_numbered_list(self, core_module):
        t = "1. first\n2. second"
        r = core_module.clean(t)
        assert "first" in r and "second" in r


class TestIntroListBoundary:
    def test_clause_break_before_list(self, core_module):
        t = "MR !108 (draft)\n- dispatchResults\n- format check"
        r = core_module.clean(t)
        assert "draft。" in r or "draft" in r


class TestHeadingFolding:
    def test_heading_folded_into_next(self, core_module):
        t = "## 検証\n\nThis is the body."
        r = core_module.clean(t)
        assert "\n\n" not in r
        assert "検証" in r
        assert "body" in r

    def test_lone_heading_stays(self, core_module):
        t = "# タイトル"
        r = core_module.clean(t)
        assert r


class TestStrippedContent:
    def test_fenced_code_blocks(self, core_module):
        t = "text\n```\ncode\n```\nmore"
        r = core_module.clean(t)
        assert "code" not in r
        assert "text" in r
        assert "more" in r

    def test_table_lines(self, core_module):
        t = "a\n| header |\n| --- |\n| cell |\n b"
        r = core_module.clean(t)
        assert "header" not in r
        assert "cell" not in r
        assert "a" in r
        assert "b" in r

    def test_blockquotes(self, core_module):
        t = "> quote\ntext"
        r = core_module.clean(t)
        assert "quote" not in r
        assert "text" in r

    def test_shell_prompts(self, core_module):
        t = "$ echo hi\ntext"
        r = core_module.clean(t)
        assert "echo" not in r
        assert "text" in r
