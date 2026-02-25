final: prev: {
  continues = final.buildNpmPackage rec {
    pname = "continues";
    version = "4.0.0";

    src = final.fetchFromGitHub {
      owner = "yigitkonur";
      repo = "cli-continues";
      rev = "819dab571c1cfd091d8812bb6d1e1da8c010f7a7";
      hash = "sha256-TMmLR2VABdWZw0C2SkJ9OjRfdTbOdBk6GYky1Y1WHN4=";
    };

    npmDepsHash = "sha256-zg3BvruFoyihjykd3piANNuCNLv1QuuqIKOcOSpvwxk=";

    npmBuildScript = "build";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/continues
      cp -r dist $out/lib/continues/
      cp -r node_modules $out/lib/continues/
      cp package.json $out/lib/continues/

      cat > $out/bin/continues << EOF
      #!/bin/sh
      exec ${final.nodejs}/bin/node $out/lib/continues/dist/cli.js "\$@"
      EOF
      chmod +x $out/bin/continues

      ln -s $out/bin/continues $out/bin/cont

      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Resume any AI coding session across Claude Code, Codex, Copilot, Gemini CLI, Cursor and more";
      homepage = "https://github.com/yigitkonur/cli-continues";
      license = licenses.mit;
      mainProgram = "continues";
    };
  };
}
