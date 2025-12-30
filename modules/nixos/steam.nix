{ config, pkgs, lib, ... }:

{
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;

    # Fix for input/click issues in Steam games on X11
    # Forces SDL2 to use X11 video backend properly
    extraCompatPackages = with pkgs; [
      proton-ge-bin
    ];
  };

  # --- gamemode (automatic performance optimizations when gaming)
  programs.gamemode.enable = true;

  # Environment variables to fix Steam input handling on X11
  environment.sessionVariables = {
    SDL_VIDEODRIVER = "x11";
  };
}
