{ config, pkgs, lib, ... }:

{
  # --- mullvad vpn service
  # nixpkgs split the package: pkgs.mullvad-vpn is now GUI-only and no longer
  # bundles the daemon. Leave .package unset (defaults to the daemon-only
  # pkgs.mullvad) and opt into the GUI via gui.enable.
  services.mullvad-vpn = {
    enable = true;
    gui.enable = true;
  };

  # --- mozilla vpn service
  services.mozillavpn.enable = true;

  # --- systemd-resolved required for mullvad to have internet access
  services.resolved.enable = true;
}
