_:

{
  flake.modules.homeManager.chromium =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.my.programs.chromium;
    in
    {
      options.my.programs.chromium.enable = lib.mkEnableOption "Chromium";

      config = lib.mkIf cfg.enable {
        programs.chromium = {
          enable = true;
          package = if pkgs.stdenv.isDarwin then null else pkgs.chromium;
          extensions = [
            { id = "gppongmhjkpfnbhagpmjfkannfbllamg"; } # Wappalyzer
            { id = "hkgfoiooedgoejojocmhlaklaeopbecg"; } # Picture-in-Picture
            { id = "dbepggeogbaibhgnhhndojpepiihcmeb"; } # Vimium
            { id = "cnjifjpddelmedmihgijeibhnjfabmlf"; } # Obsidian Web Clipper
            { id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa"; } # 1Password
            { id = "kpgefcfmnafjgpblomihpgmejjdanjjp"; } # nos2x
            { id = "fcoeoabgfenejglbffodgkkbkcdhcgfn"; } # Claude
            { id = "lkihjlcipnbgeokmfnpogjfflofbfhga"; } # Are.na
            { id = "opfckbclghgjapgbpncggbllfpiegnbm"; } # Miro
            { id = "nkbihfbeogaeaoehlefnkodbefgpgknn"; } # MetaMask
            { id = "nibjojkomfdiaoajekhjakgkdhaomnch"; } # IPFS Companion
            { id = "neebplgakaahbhdphmkckjjcegoiijjo"; } # Keepa
            { id = "kpffakljoffeckbckheiheogajnofdpc"; } # Amazonの個人情報を隠します
            { id = "pjginhohpenlemfdcjbahjbhnpinfnlm"; } # CRX GCal URL Opener
          ];
        };
      };
    };
}
