{ config, pkgs, lib, ... }:

let secrets = import ../secrets.nix; in
{
  imports = [
    # --- shared modules
    ../modules/home-manager/zsh.nix
    ../modules/home-manager/starship.nix
    ../modules/home-manager/neofetch.nix
    ../modules/home-manager/fonts.nix
    ../modules/home-manager/git.nix
    ../modules/home-manager/direnv.nix
    # --- macOS-specific
    ../modules/darwin/zsh.nix
    ../modules/darwin/git.nix
  ];

  # --- allow unfree (standalone HM needs this explicitly)
  nixpkgs.config.allowUnfree = true;

  home.username = secrets.macUser;
  home.homeDirectory = "/Users/${secrets.macUser}";

  xdg.enable = true;

  # --- XDG-compliant zsh location (silences dotDir deprecation warning)
  programs.zsh.dotDir = "${config.xdg.configHome}/zsh";

  # --- shared packages (system-level on NixOS, user-level here)
  home.packages =
    (import ../modules/shared/system-packages.nix { inherit pkgs; }) ++
    (import ../modules/shared/home-packages.nix { inherit pkgs; }) ++
    (with pkgs; [
      # --- macOS-only packages
      btop
      gawk
    ]);

  # --- home manager state version
  home.stateVersion = "25.11";

  # --- home manager self management
  programs.home-manager.enable = true;
}
