{ config, pkgs, lib, ... }:

{
  # --- starship config moved to modules/home-manager/starship.nix
  # this module is kept for the system-level starship package
  environment.systemPackages = with pkgs; [ starship ];
}
