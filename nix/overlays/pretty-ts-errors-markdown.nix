{
  sources,
  final,
  prev,
}:
{
  pretty-ts-errors-markdown = final.buildNpmPackage {
    inherit (sources.pretty-ts-errors-markdown) pname version src;

    npmDepsHash = sources.pretty-ts-errors-markdown.npmDepsHash;

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
