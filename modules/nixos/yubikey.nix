{ config, pkgs, lib, ... }:

{
  # --- udev rules for FIDO2/U2F devices (YubiKey, etc.)
  hardware.u2f.enable = true;

  # --- YubiKey management tools
  environment.systemPackages = with pkgs; [
    yubikey-manager  # ykman CLI for configuration and status
  ];
}
