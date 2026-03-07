# tree-sitter-moonbit grammar (not yet in nixpkgs)
final: prev: {
  tree-sitter-moonbit-grammar = prev.stdenv.mkDerivation {
    pname = "tree-sitter-moonbit-grammar";
    version = "0-unstable";
    src = prev._tree-sitter-moonbit;
    buildInputs = [ prev.tree-sitter ];
    buildPhase = ''
      cd src
      $CC -shared -fPIC -o parser.so parser.c scanner.c -I .
    '';
    installPhase = ''
      mkdir -p $out/parser
      cp parser.so $out/parser/moonbit.so
      cd ..
      if [ -d queries ]; then
        mkdir -p $out/queries/moonbit
        cp queries/*.scm $out/queries/moonbit/
      fi
    '';
  };
}
