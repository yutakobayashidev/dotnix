{ pkgs }:
{
  default = "DuckDuckGo Lite";

  engines = {
    "DuckDuckGo Lite" = {
      urls = [
        {
          template = "https://lite.duckduckgo.com/lite/?q={searchTerms}";
        }
      ];
      icon = "https://duckduckgo.com/favicon.ico";
    };

    chatgpt = {
      name = "ChatGPT";
      urls = [ { template = "https://chatgpt.com/?q={searchTerms}"; } ];
      definedAliases = [ "@chatgpt" ];
    };

    tw-lite = {
      name = "tw-lite Latest";
      urls = [
        {
          template = "https://tw-lite.home.yutakobayashi.com/search?q={searchTerms}&product=Latest&following=true";
        }
      ];
      definedAliases = [ "@tw" ];
    };

    nix-packages = {
      name = "Nix Packages";
      urls = [
        {
          template = "https://search.nixos.org/packages";
          params = [
            {
              name = "type";
              value = "packages";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ "@np" ];
    };

    nixos-wiki = {
      name = "NixOS Wiki";
      urls = [ { template = "https://wiki.nixos.org/w/index.php?search={searchTerms}"; } ];
      icon = "https://wiki.nixos.org/favicon.ico";
      definedAliases = [ "@nw" ];
    };

    noogle = {
      name = "noogle";
      urls = [ { template = "https://noogle.dev/q?term={searchTerms}"; } ];
      icon = "https://noogle.dev/favicon.png";
      definedAliases = [ "@noogle" ];
    };

    crates-io = {
      name = "crates.io";
      urls = [ { template = "https://crates.io/search?q={searchTerms}"; } ];
      icon = "https://crates.io/favicon.ico";
      definedAliases = [ "@crates" ];
    };

    npm = {
      name = "npm";
      urls = [ { template = "https://www.npmjs.com/search?q={searchTerms}"; } ];
      icon = "https://www.google.com/s2/favicons?domain=npmjs.com&sz=64";
      definedAliases = [ "@npm" ];
    };

    pypi = {
      name = "PyPI";
      urls = [ { template = "https://pypi.org/search/?q={searchTerms}"; } ];
      icon = "https://pypi.org/favicon.ico";
      definedAliases = [ "@pypi" ];
    };

    nixos-options = {
      name = "NixOS Options";
      urls = [
        {
          template = "https://search.nixos.org/options";
          params = [
            {
              name = "channel";
              value = "unstable";
            }
            {
              name = "query";
              value = "{searchTerms}";
            }
          ];
        }
      ];
      icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
      definedAliases = [ "@no" ];
    };

    docs-rs = {
      name = "docs.rs";
      urls = [ { template = "https://docs.rs/releases/search?query={searchTerms}"; } ];
      icon = "https://docs.rs/favicon.ico";
      definedAliases = [ "@docs" ];
    };

    grep-app = {
      name = "grep.app";
      urls = [ { template = "https://grep.app/search?q={searchTerms}"; } ];
      icon = "https://grep.app/favicon.ico";
      definedAliases = [ "@grep" ];
    };

    terraform-registry = {
      name = "Terraform Registry";
      urls = [ { template = "https://registry.terraform.io/search/providers?q={searchTerms}"; } ];
      icon = "https://registry.terraform.io/favicon.ico";
      definedAliases = [ "@tf" ];
    };
  };

  force = true;
}
