{ lib }:
let
  workContainerId = 1;
  schoolContainerId = 2;

  work = host: {
    inherit host;
    cookieStoreId = "firefox-container-${toString workContainerId}";
    containerName = "work";
    enabled = true;
  };

  school = host: {
    inherit host;
    cookieStoreId = "firefox-container-${toString schoolContainerId}";
    containerName = "school";
    enabled = true;
  };
in
{
  containers = {
    work = {
      id = workContainerId;
      color = "red";
      icon = "briefcase";
    };
    school = {
      id = schoolContainerId;
      color = "blue";
      icon = "fruit";
    };
  };
  containersForce = true;

  extensionSettings."containerise@kinte.sh" = {
    force = true;
    settings = {
      "map=github.com/orgs/Litela-HQ" = work "github.com/orgs/Litela-HQ";
      "map=github.com/Litela-HQ" = work "github.com/Litela-HQ";
    }
    // lib.listToAttrs (
      map (host: lib.nameValuePair "map=${host}" (school host)) [
        "nlobby.nnn.ed.jp"
        "www.nnn.ed.nico"
      ]
    );
  };
}
