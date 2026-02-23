final: prev: {
  difit = final.stdenv.mkDerivation (finalAttrs: {
    pname = "difit";
    version = "3.1.10";

    src = final.fetchFromGitHub {
      owner = "yoshiko-pg";
      repo = "difit";
      rev = "v${finalAttrs.version}";
      hash = "sha256-Yr7x8NJJP3X8YP5tGNMmn4mUxrmz3RMvnx9MPz4jj7o=";
    };

    nativeBuildInputs = [
      final.nodejs
      final.pnpm_10
      final.pnpmConfigHook
      final.git
    ];

    pnpmDeps = final.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-IRCr/Fo0lgv+JSMIYrTpyWgGA6EORCNL+igK88dkJNg=";
      fetcherVersion = 3;
    };

    buildPhase = ''
      runHook preBuild
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
            runHook preInstall

            mkdir -p $out/bin $out/lib/difit
            cp -r dist $out/lib/difit/
            cp -r node_modules $out/lib/difit/
            cp package.json $out/lib/difit/

            cat > $out/bin/difit << EOF
      #!/bin/sh
      exec ${final.nodejs}/bin/node $out/lib/difit/dist/cli/index.js "\$@"
      EOF
            chmod +x $out/bin/difit

            runHook postInstall
    '';

    meta = with final.lib; {
      description = "A lightweight CLI tool for reviewing Git diffs with a GitHub-style viewer";
      homepage = "https://github.com/yoshiko-pg/difit";
      license = licenses.mit;
      mainProgram = "difit";
    };
  });
}
