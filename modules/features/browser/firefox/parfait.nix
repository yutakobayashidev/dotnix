{ fetchFromGitHub }:
let
  # renovate: datasource=github-releases depName=reizumii/parfait extractVersion=^v(?<version>.+)$
  version = "1.0";
in
fetchFromGitHub {
  owner = "reizumii";
  repo = "parfait";
  tag = "v${version}";
  hash = "sha256-nUlkkZ60WLEottauGLX8QZAaT4tZlE/dzfIAm/CaB4k=";
}
