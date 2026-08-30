{ ... }:

{
  # --- Minecraft server port (TCP + UDP)
  networking.firewall.allowedTCPPorts = [ 25565 ];
  networking.firewall.allowedUDPPorts = [ 25565 ];
}
