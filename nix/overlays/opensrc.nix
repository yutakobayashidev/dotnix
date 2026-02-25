final: prev: {
  opensrc = final.stdenv.mkDerivation (finalAttrs: {
    pname = "opensrc";
    version = "0.6.0";

    src = final.fetchFromGitHub {
      owner = "vercel-labs";
      repo = "opensrc";
      rev = "1fe9dbcafb8ee54010cea75e651190f903ab4e69";
      hash = "sha256-oHI1NX20IpvwyExN0bBv79FoUihkHV5+N4DlWlPWNMQ=";
    };

    pnpmDeps = final.fetchPnpmDeps {
      inherit (finalAttrs) pname version src;
      hash = "sha256-B551p4mbmZwWYsnnkrE+9QN7mga799NWeF11rNzC2rw=";
      fetcherVersion = 3;
      pnpm = final.pnpm_9;
    };

    nativeBuildInputs = [
      final.nodejs
      (final.pnpmConfigHook.override { pnpm = final.pnpm_9; })
      final.pnpm_9
    ];

    buildPhase = ''
      runHook preBuild
      pnpm build
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/opensrc
      cp -r dist $out/lib/opensrc/
      cp -r node_modules $out/lib/opensrc/
      cp package.json $out/lib/opensrc/

      cat > $out/bin/opensrc << EOF
      #!/bin/sh
      exec ${final.nodejs}/bin/node $out/lib/opensrc/dist/index.js "\$@"
      EOF
      chmod +x $out/bin/opensrc

      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Fetch and manage source code from package registries for AI coding agents";
      homepage = "https://github.com/vercel-labs/opensrc";
      license = licenses.mit;
      mainProgram = "opensrc";
    };
  });
}
