_:

let
  espPart = "/dev/disk/by-partuuid/a53e3b19-67de-40de-9ded-3eac3117689a";
  nixosPart = "/dev/disk/by-partuuid/311d0f9c-f35f-42e6-b6fc-a4d67dd21b2e";

  btrfsMountOptions = [
    "compress=zstd:1"
    "noatime"
  ];
in
{
  disko.devices.disk = {
    esp = {
      type = "disk";
      device = espPart;
      destroy = false;

      content = {
        type = "filesystem";
        format = "vfat";
        mountpoint = "/boot";
        mountOptions = [ "umask=0077" ];
      };
    };

    nixos = {
      type = "disk";
      device = nixosPart;
      destroy = false;

      content = {
        type = "luks";
        name = "cryptroot";
        passwordFile = "/tmp/luks-password";
        settings.allowDiscards = true;

        content = {
          type = "btrfs";
          extraArgs = [
            "-f"
            "-L"
            "nixos"
          ];
          subvolumes = {
            "@root" = {
              mountpoint = "/";
              mountOptions = btrfsMountOptions;
            };
            "@home" = {
              mountpoint = "/home";
              mountOptions = btrfsMountOptions;
            };
            "@nix" = {
              mountpoint = "/nix";
              mountOptions = btrfsMountOptions;
            };
            "@persist" = {
              mountpoint = "/persist";
              mountOptions = btrfsMountOptions;
            };
            "@log" = {
              mountpoint = "/var/log";
              mountOptions = btrfsMountOptions;
            };
            "@swap" = {
              mountpoint = "/.swapvol";
              swap.swapfile.size = "32G";
            };
          };
        };
      };
    };
  };
}
