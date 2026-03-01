final: prev: {
  readout = prev.stdenvNoCC.mkDerivation (finalAttrs: {
    pname = "readout";
    version = "0.0.5";

    src = final.fetchurl {
      url = "https://readout-updates.vercel.app/downloads/Readout-${finalAttrs.version}.dmg";
      hash = "sha256-O91J6okRAO2vQJWmML6XSgcda2zuSErIKEAQ7DJH5To=";
    };

    nativeBuildInputs = [ final.undmg ];
    sourceRoot = ".";

    phases = [
      "unpackPhase"
      "installPhase"
    ];

    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications
      cp -pR "Readout.app" $out/Applications/
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Readout";
      homepage = "https://readout-updates.vercel.app";
      appcast = "https://readout-updates.vercel.app/appcast.xml";
      platforms = platforms.darwin;
      sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    };
  });
}
