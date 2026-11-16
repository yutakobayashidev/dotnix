{
  pkgs,
  settings,
  skillsShellHook,
}:
{
  analysis ? false,
  nativeAnalysis ? false,
  extraPackages ? [ ],
}:
let
  inherit (pkgs) lib;
  imageType = if analysis then "default" else "google_apis";
  composition = pkgs.androidenv.composeAndroidPackages {
    platformVersions = [ settings.platformVersion ];
    buildToolsVersions = [ settings.buildToolsVersion ];
    toolsVersion = null;
    includeCmake = false;
    includeNDK = false;
    includeEmulator = settings.emulator;
    includeSystemImages = settings.emulator;
    systemImageTypes = [ imageType ];
    abiVersions = [ "x86_64" ];
  };
  sdk = "${composition.androidsdk}/libexec/android-sdk";
  mobile = pkgs.writeShellApplication {
    name = "mobile";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.android-cli
    ];
    text = builtins.readFile ../scripts/mobile.sh;
  };
in
pkgs.mkShell {
  packages = [
    pkgs.android-cli
    pkgs.maestro
    composition.androidsdk
    pkgs.jdk21
    pkgs.git
    mobile
  ]
  ++ lib.optionals analysis [
    pkgs.jadx
    pkgs.apktool
    pkgs.frida-tools
    pkgs.mitmproxy
  ]
  ++ lib.optionals nativeAnalysis [ pkgs.ghidra ]
  ++ extraPackages;

  JAVA_HOME = pkgs.jdk21.home;
  ANDROID_HOME = sdk;
  ANDROID_SDK_ROOT = sdk;
  MOBILE_IMAGE = "system-images;android-${settings.platformVersion};${imageType};x86_64";
  MOBILE_AVD = "mobile-${if analysis then "analysis" else "dev"}-${settings.platformVersion}";
  MOBILE_PORT = if analysis then "5556" else "5554";
  MOBILE_EMULATOR = if settings.emulator then "1" else "0";
  MOBILE_ANALYSIS = if analysis then "1" else "0";

  shellHook = ''
    # cmdline-tools also ships an `android` bootstrapper; prefer the pinned CLI.
    export PATH="${pkgs.android-cli}/bin:$PATH"
    export MOBILE_WORKSPACE="$PWD"
    export ANDROID_USER_HOME="$MOBILE_WORKSPACE/.mobile/android"
    export ANDROID_AVD_HOME="$ANDROID_USER_HOME/avd"
    export GRADLE_USER_HOME="$MOBILE_WORKSPACE/.mobile/gradle"
    export GRADLE_OPTS="''${GRADLE_OPTS:+$GRADLE_OPTS }-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdk}/build-tools/${settings.buildToolsVersion}/aapt2"
    mkdir -p "$ANDROID_AVD_HOME" "$GRADLE_USER_HOME"
    ${skillsShellHook}
  '';
}
