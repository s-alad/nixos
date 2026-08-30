{ pkgs }:

# Shared font set installed on every machine (system-level on NixOS via
# fonts.packages, user-level on darwin via home.packages).
with pkgs; [
  roboto
  nerd-fonts.iosevka
  nerd-fonts.dejavu-sans-mono
  comic-mono
  aileron
  atkinson-hyperlegible
  cantarell-fonts
]
