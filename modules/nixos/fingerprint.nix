{ config, pkgs, lib, ... }:

{
  # --- (Synaptics 06cb:00f9)
  services.fprintd.enable = true;

  # --- PAM integration for fingerprint auth
  security.pam.services = {
    login.fprintAuth = true;                  # General login
    lightdm.fprintAuth = true;                # Display manager login
    sudo.fprintAuth = true;                   # Sudo commands
    polkit-1.fprintAuth = true;               # System authorization
    cinnamon-screensaver.fprintAuth = true;   # Screen unlock
  };

  # --- disable USB autosuspend for fingerprint reader (prevents connectivity issues)
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00f9", ATTR{power/autosuspend}="-1"
  '';

  # --- stop fprintd before suspend to prevent database corruption
  powerManagement.powerDownCommands = ''
    ${pkgs.systemd}/bin/systemctl stop fprintd.service || true
  '';
}
