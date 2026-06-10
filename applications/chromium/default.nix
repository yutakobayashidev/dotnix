{ pkgs, ... }:

{
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
}
