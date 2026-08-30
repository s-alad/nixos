{ pkgs, ... }:
{
  # --- BE201 wifi offload fix: disable TSO/GSO/TX offload when the wifi NIC comes up.
  # The dispatcher fires for every interface; the iface check scopes it to salad's
  # wifi NIC (wlp0s20f3) — host-specific, update if the interface name changes.
  networking.networkmanager.dispatcherScripts = [{
    type = "basic";
    source = pkgs.writeShellScript "wifi-offload-fix" ''
      iface="$1"
      action="$2"
      if [ "$iface" = "wlp0s20f3" ] && [ "$action" = "up" ]; then
        ${pkgs.ethtool}/bin/ethtool -K "$iface" tso off gso off tx off
      fi
    '';
  }];
}
