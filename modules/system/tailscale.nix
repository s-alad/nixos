{ config, pkgs, lib, ... }:

{
  # --- tailscale mesh VPN
  services.tailscale.enable = true;

  # allow incoming connections on the tailscale interface
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # open Minecraft server port (both TCP and UDP)
  networking.firewall.allowedTCPPorts = [ 25565 ];
  networking.firewall.allowedUDPPorts = [ 25565 ];
}
