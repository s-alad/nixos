{ pkgs, ... }:
{
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
