{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;

    # --- import starship config from /etc/nixos/config.toml
    settings = lib.importTOML ../config.toml;
  };
}
