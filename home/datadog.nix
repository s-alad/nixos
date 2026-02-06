{ config, pkgs, lib, ... }:

{
  imports = [
    # --- shared modules
    ../modules/home-manager/zsh.nix
    ../modules/home-manager/starship.nix
    ../modules/home-manager/neofetch.nix
    ../modules/home-manager/fonts.nix
    ../modules/home-manager/git.nix
    # --- macOS-specific
    ../modules/darwin/zsh.nix
    ../modules/darwin/git.nix
  ];

  # --- allow unfree (standalone HM needs this explicitly)
  nixpkgs.config.allowUnfree = true;

  home.username = "saad.naji";
  home.homeDirectory = "/Users/saad.naji";

  xdg.enable = true;

  # --- direnv + nix-direnv (same as NixOS)
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
    config.global.hide_env_diff = true;
  };

  home.sessionVariables = {
    DIRENV_LOG_FORMAT = "";
  };

  # --- shared packages (system-level on NixOS, user-level here)
  home.packages =
    (import ../modules/shared/system-packages.nix { inherit pkgs; }) ++
    (import ../modules/shared/home-packages.nix { inherit pkgs; }) ++
    (with pkgs; [
      # --- macOS-only packages
    ]);

  # --- backup conflicting dotfiles instead of failing
  home.backupFileExtension = "backup";

  # --- home manager state version
  home.stateVersion = "25.11";

  # --- home manager self management
  programs.home-manager.enable = true;
}
