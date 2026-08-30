{ pkgs, ... }:

{
  # --- system fonts (shared set in packages/fonts.nix + NixOS-only extras)
  fonts.fontDir.enable = true;

  fonts.packages = (import ../../packages/fonts.nix { inherit pkgs; }) ++ (with pkgs; [
    adwaita-fonts
  ]);
}
