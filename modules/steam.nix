{ config, pkgs, lib, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  # gamemode (automatic performance optimizations when gaming)
  programs.gamemode.enable = true;
}
