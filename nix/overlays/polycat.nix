{
  sources,
  final,
  prev,
}:
{
  polycat = final.stdenv.mkDerivation {
    inherit (sources.polycat) pname src;
    version = "unstable-${sources.polycat.date}";

    makeFlags = [ "PREFIX=$(out)" ];

    meta = with final.lib; {
      description = "Runcat module for polybar/waybar written in C++";
      homepage = "https://github.com/2IMT/polycat";
      license = licenses.mit;
      platforms = platforms.linux;
    };
  };
}
