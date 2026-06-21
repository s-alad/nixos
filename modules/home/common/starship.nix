{ config, pkgs, lib, ... }:

{
  programs.starship = {
    enable = true;

    # --- import starship config from configs/starship.toml
    settings = lib.importTOML ../../../configs/starship.toml;
  };
}
