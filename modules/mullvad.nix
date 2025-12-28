{ config, pkgs, lib, ... }:

{
  # --- mullvad vpn service
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };

  # --- systemd-resolved required for mullvad to have internet access
  services.resolved.enable = true;
}
