{
  services = {
    tlp.enable = true;

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
