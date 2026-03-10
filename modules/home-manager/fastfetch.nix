{ config, pkgs, ... }:

{
  # fastfetch replaces neofetch (removed from nixpkgs)
  # Theme ported from neofetch IdliDev theme with NixOS ASCII art
  # Config stored as files to preserve UTF-8 nerd font icons

  xdg.configFile."fastfetch/config.jsonc".source = ../../configs/fastfetch.jsonc;
  xdg.configFile."fastfetch/ascii.txt".source = ../../configs/fastfetch-ascii.txt;
}
