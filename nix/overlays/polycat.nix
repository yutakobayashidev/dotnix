final: prev: {
  polycat = final.stdenv.mkDerivation rec {
    pname = "polycat";
    version = "2.0.0";

    src = final.fetchFromGitHub {
      owner = "2IMT";
      repo = "polycat";
      rev = "main";
      hash = "sha256-wpDx6hmZe/dLv+F+kbo+YUIZ2A8XgnrZP0amkz6I5IQ=";
    };

    makeFlags = [ "PREFIX=$(out)" ];

    meta = with final.lib; {
      description = "Runcat module for polybar/waybar written in C++";
      homepage = "https://github.com/2IMT/polycat";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };
}
