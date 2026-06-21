{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    roboto
    nerd-fonts.iosevka
    nerd-fonts.dejavu-sans-mono
    comic-mono
    aileron
    atkinson-hyperlegible
    cantarell-fonts
  ];

  # enable fontconfig for user-level font discovery
  fonts.fontconfig.enable = true;
}
