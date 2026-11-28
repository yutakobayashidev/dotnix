_:

{
  disko.devices.disk.main = {
    type = "disk";
    # Vultr attaches the boot disk as virtio-blk.
    device = "/dev/vda";
    content = {
      type = "gpt";
      partitions = {
        # GRUB stores its core image here when the instance boots with legacy BIOS.
        bios = {
          size = "1M";
          type = "EF02";
        };

        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "umask=0077" ];
          };
        };

        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
          };
        };
      };
    };
  };
}
