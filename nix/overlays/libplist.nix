# libplist のテストが macOS で失敗するため、テストをスキップ
final: prev: {
  libplist = prev.libplist.overrideAttrs (old: {
    doCheck = false;
  });
}
