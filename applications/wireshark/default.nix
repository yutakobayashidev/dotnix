{
  programs.wireshark = {
    enable = true;
    # Allow users in the "wireshark" group to capture network traffic via dumpcap.
    dumpcap.enable = true;
    # USB capture requires extra udev rules; keep it disabled by default.
    usbmon.enable = false;
  };
}
