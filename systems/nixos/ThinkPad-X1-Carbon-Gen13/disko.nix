_:

let
  espPart = "/dev/disk/by-partuuid/8cb2bef8-44e0-4db0-af89-4412783ec3fb";
  nixosPart = "/dev/disk/by-partuuid/ac37857a-9a50-48e9-89f2-bd04175d926f";

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
