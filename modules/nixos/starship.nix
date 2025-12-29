{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;

    # --- import starship config from /etc/nixos/configs/starship.toml
    settings = lib.importTOML ../../configs/starship.toml;
  };
}
