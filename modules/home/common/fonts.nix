{ pkgs, lib, ... }:

{
  # On NixOS the shared fonts come from system `fonts.packages`; install them at
  # the user level only on darwin (which has no system font path).
  home.packages = lib.optionals pkgs.stdenv.isDarwin (import ../../../packages/fonts.nix { inherit pkgs; });

  # enable fontconfig for user-level font discovery
  fonts.fontconfig.enable = true;
}
