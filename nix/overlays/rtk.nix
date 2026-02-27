# rtk - LLMトークン消費を60-90%削減するCLIプロキシ
final: prev: {
  rtk = final.rustPlatform.buildRustPackage rec {
    pname = "rtk";
    version = "0.22.2";

    src = final.fetchFromGitHub {
      owner = "rtk-ai";
      repo = "rtk";
      rev = "v${version}";
      hash = "sha256-dNODYk5PNiKU6+9AgB9c5f06PCcjStwFPEpuIb+BT0g=";
    };

    cargoHash = "sha256-lgmgorgT/KDSyzEcE33qkPF4f/3LJbAzEH0s9thTohE=";

    # tracking::tests がNixサンドボックス内でSQLite/HOMEの制約により失敗するためスキップ
    doCheck = false;

    meta = with final.lib; {
      description = "CLI proxy that reduces LLM token consumption by 60-90%";
      homepage = "https://github.com/rtk-ai/rtk";
      license = licenses.mit;
      mainProgram = "rtk";
    };
  };
}
