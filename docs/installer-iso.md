# NixOS Installer ISO

This repository provides a custom x86_64 NixOS installer with the tools needed to install the configured hosts.

## Build the ISO

Build the installer from the dotnix checkout:

```sh
nix build .#nixosConfigurations.installer.config.system.build.isoImage
```

The ISO is written to `result/iso/*.iso`.

## Write the ISO Directly

List block devices and identify the USB drive by its model, serial number, size, and transport:

```sh
lsblk -o NAME,PATH,SIZE,MODEL,SERIAL,VENDOR,TRAN,HOTPLUG,RM,TYPE,FSTYPE,LABEL,MOUNTPOINTS
```

The following operation destroys all data on the selected device. Replace `/dev/sdX` with the whole USB device, not a partition such as `/dev/sdX1`:

```sh
sudo dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync
sync
```

Recheck the device path immediately before running `dd`. Do not unplug the drive until both commands finish.

## Ventoy Alternative

If the USB drive already uses Ventoy, mount its data partition and copy the ISO instead of writing it with `dd`:

```sh
sudo mkdir -p /mnt/ventoy
sudo mount /dev/sdX1 /mnt/ventoy
sudo cp result/iso/*.iso /mnt/ventoy/
sync
sudo umount /mnt/ventoy
```

Do not unplug the drive while `sync` or `umount` is running. Select the copied ISO from the Ventoy menu at boot.

## Boot and Connect

Boot the target machine from the USB drive. The installer starts NetworkManager, obtains an address through DHCP on a wired connection, and logs root in automatically on the console.

Set a temporary root password on the target before using SSH:

```sh
passwd
ip -brief address
```

Then connect from another machine if remote installation is useful:

```sh
ssh root@<TARGET_IP>
```

Run `installer-help` in the installer to display its network, SSH, Wi-Fi, and repository-clone reminders again.
