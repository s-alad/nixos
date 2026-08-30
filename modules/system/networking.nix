{ ... }:

{
  # --- hostname
  networking.hostName = "salad";
  # --- enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  # --- captive portal detection (airline wifi, hotel wifi, etc.)
  networking.networkmanager.settings.connectivity = {
    uri = "http://nmcheck.gnome.org/check_network_status.txt";
    interval = 300;
  };
  # --- firewall (service-specific ports live in their own modules, e.g. minecraft.nix, steam.nix)
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # networking.firewall.enable = false;
}
