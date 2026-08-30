{ ... }:

{
  # --- tailscale mesh VPN
  services.tailscale.enable = true;

  # allow incoming connections on the tailscale interface
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
