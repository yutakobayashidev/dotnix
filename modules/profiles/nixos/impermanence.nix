{ inputs, username, ... }:

{
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  fileSystems = {
    "/persist".neededForBoot = true;
    "/var/log".neededForBoot = true;
    "/home".neededForBoot = true;
  };

  boot.initrd.systemd.services.rollback = {
    description = "Rollback btrfs root subvolume to a blank snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "cryptsetup.target" ];
    before = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = "no";
    serviceConfig.Type = "oneshot";
    script = ''
      mkdir -p /mnt
      mount -t btrfs -o subvol=/ /dev/mapper/cryptroot /mnt

      if [[ -e /mnt/@root ]]; then
        mkdir -p /mnt/@old_roots
        timestamp=$(date +%Y%m%d_%H%M%S)
        mv /mnt/@root "/mnt/@old_roots/@root_$timestamp"
      fi

      for old in /mnt/@old_roots/@root_*; do
        if [[ -e "$old" ]]; then
          create_time=$(stat -c %Y "$old")
          current_time=$(date +%s)
          age_days=$(( (current_time - create_time) / 86400 ))
          if [[ $age_days -gt 7 ]]; then
            btrfs subvolume list -o "$old" | cut -f9 -d' ' | while read subvolume; do
              btrfs subvolume delete "/mnt/$subvolume" 2>/dev/null || true
            done
            btrfs subvolume delete "$old" 2>/dev/null || true
          fi
        fi
      done

      btrfs subvolume create /mnt/@root
      umount /mnt
    '';
  };

  environment.persistence."/persist" = {
    hideMounts = true;
    directories = [
      "/etc/NetworkManager/system-connections"
      "/etc/nixos"
      "/var/lib"
    ];
    files = [ "/etc/machine-id" ];
  };

  systemd.tmpfiles.rules = [
    "d /persist/home 0755 root root -"
    "d /persist/home/${username} 0700 ${username} users -"
  ];

  programs.fuse.userAllowOther = true;

  security.sudo.extraConfig = ''
    Defaults lecture = never
  '';
}
