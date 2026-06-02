class TestForceSplitRoundtrip:
    def test_short_text_passthrough(self, core_module):
        t = "hello world"
        assert core_module._force_split(t, 60) == [t]

    def test_long_text_splits(self, core_module):
        t = "a " * 100
        chunks = core_module._force_split(t, 50)
        assert "".join(chunks) == t
        for c in chunks:
            assert len(c) <= 50

    def test_no_space_in_budget(self, core_module):
        t = "a" * 100
        chunks = core_module._force_split(t, 30)
        assert all(len(c) <= 30 for c in chunks)

    def test_space_boundary_respected(self, core_module):
        t = "hello world " * 12
        chunks = core_module._force_split(t, 30)
        assert all(len(c) <= 30 for c in chunks)
        assert "".join(chunks) == t


class TestForceSplitWordBoundary:
    def test_words_not_broken(self, core_module):
        t = "consumer producer " * 20
        chunks = core_module._force_split(t, 25)
        for c in chunks:
            assert len(c) <= 25
        assert "".join(chunks) == t


class TestSplitIntoChunks:
    def test_empty(self, core_module):
        assert core_module.split_into_chunks("") == []

    def test_single_paragraph(self, core_module):
        t = "hello world."
        assert core_module.split_into_chunks(t) == [t]

    def test_first_chunk_small(self, core_module):
        t = "A" * 200 + "。" + "B" * 200 + "。"
        chunks = core_module.split_into_chunks(t)
        assert len(chunks[0]) <= core_module.FIRST_CHUNK_MAX
        assert all(len(c) <= core_module.LATER_CHUNK_MAX for c in chunks[1:])

    def test_multiple_paragraphs(self, core_module):
        t = "A。" * 10 + "\n\n" + "B。" * 10
        chunks = core_module.split_into_chunks(t)
        assert len(chunks) >= 2

    def test_whitespace_only(self, core_module):
        assert core_module.split_into_chunks("  \n\n  ") == []


class TestCommaIsNotASplitBoundary:
    def test_japanese_comma_not_split(self, core_module):
        t = "A、B、C。D、E。"
        result = core_module._split_paragraph(t, 80)
        assert len(result) == 2
        assert result[0] == "A、B、C。"
        assert result[1] == "D、E。"

    def test_chinese_comma_not_split(self, core_module):
        t = "ABC，DEF。GHI。"
        result = core_module._split_paragraph(t, 80)
        assert len(result) == 2
        assert result[0] == "ABC，DEF。"
        assert result[1] == "GHI。"

    def test_ascii_comma_not_split(self, core_module):
        t = "A,B,C.D,E."
        result = core_module._split_paragraph(t, 80)
        assert len(result) == 2

    def test_period_still_splits(self, core_module):
        t = "A, B, C. D, E. F."
        result = core_module._split_paragraph(t, 80)
        assert len(result) >= 2


class TestIntegratedPipeline:
    def test_realistic_markdown(self, core_module):
        md = (
            "## 検証\n\n"
            "このPRはdispatchResults関数の戻り値がnullの場合に"
            "クラッシュする問題を修正します。\n\n"
            "- 戻り値がnullのときに早期returnするよう変更\n"
            "- 該当箇所のテストケースを追加\n"
        )
        text = core_module.clean(md)
        assert text
        chunks = core_module.split_into_chunks(text)
        assert chunks
        assert "".join(chunks) == text
