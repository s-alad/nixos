{ config, pkgs, lib, ... }:

{
  fonts.fontDir.enable = true;

  fonts.packages = with pkgs; [
    roboto
    nerd-fonts.iosevka
    comic-mono
    aileron
    atkinson-hyperlegible
    cantarell-fonts
    adwaita-fonts
  ];
}
