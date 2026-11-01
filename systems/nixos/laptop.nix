{
  imports = [
    ./services/comin
    ../shared/comin/laptop.nix
  ];

  systemd.user.services.comin-desktop.serviceConfig = {
    Restart = "on-failure";
    RestartSec = 10;
  };

  services = {
    tlp.enable = true;
    # TLP owns power management; override Noctalia's recommended default.
    power-profiles-daemon.enable = false;

    upower = {
      enable = true;
      usePercentageForPolicy = true;
      percentageLow = 20;
      percentageCritical = 10;
      percentageAction = 5;
      criticalPowerAction = "PowerOff";
    };
  };

  hardware.trackpoint = {
    enable = true;
    emulateWheel = true;
  };
}
