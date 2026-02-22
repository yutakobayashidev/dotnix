final: prev: {
  pretty-ts-errors-markdown = final.buildNpmPackage rec {
    pname = "pretty-ts-errors-markdown";
    version = "0.0.15";

    src = final.fetchFromGitHub {
      owner = "hexh250786313";
      repo = "pretty-ts-errors-markdown";
      rev = "4d4a167d4cc9bd6c07945c89441b154746e2b2d6";
      hash = "sha256-zxp8YAfF15sE8EZmO3IFB7PmJAw9GfGhGlJQs0qliz4=";
    };

    npmDepsHash = "sha256-aC+t2FYWJgDzXmfYg2IDJ7W2pLPAZ1o3TC68MWZhbSg=";

    nativeBuildInputs = [ final.rsync ];

    npmBuildScript = "build";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib
      cp -r lib $out/lib/
      cp -r bin $out/lib/
      cp -r node_modules $out/lib/
      cp package.json $out/lib/

      cat > $out/bin/pretty-ts-errors-markdown << EOF
#!/bin/sh
exec ${final.nodejs}/bin/node $out/lib/bin/pretty-ts-errors-markdown.js "\$@"
EOF
      chmod +x $out/bin/pretty-ts-errors-markdown

      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Convert pretty-ts-errors HTML output to Markdown";
      homepage = "https://github.com/hexh250786313/pretty-ts-errors-markdown";
      license = licenses.mit;
      mainProgram = "pretty-ts-errors-markdown";
    };
  };
}
