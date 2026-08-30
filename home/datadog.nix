{ config, pkgs, lib, ... }:

let
  secrets = import ../secrets.nix;
  devenv-init = import ../lib/devenv-init.nix { inherit pkgs; };
in
{
  imports = [
    # --- shared modules
    ../modules/home/common/zsh.nix
    ../modules/home/common/starship.nix
    ../modules/home/common/fastfetch.nix
    ../modules/home/common/fonts.nix
    ../modules/home/common/git.nix
    ../modules/home/common/direnv.nix
    ../modules/home/common/pass.nix
    ../modules/home/common/xdg-dotfiles.nix
    # --- macOS-specific
    ../modules/home/darwin/zsh.nix
    ../modules/home/darwin/git.nix
  ];

  # --- allow unfree (standalone HM needs this explicitly)
  nixpkgs.config.allowUnfree = true;

  home.username = secrets.macUser;
  home.homeDirectory = "/Users/${secrets.macUser}";

  xdg.enable = true;

  # --- tidy up dotfile clutter into XDG state dirs (NODE_REPL_HISTORY shared via common/xdg-dotfiles.nix)
  home.sessionVariables = {
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    VIMINFOFILE = "${config.xdg.stateHome}/vim/viminfo";
  };

  # --- shared packages (system-level on NixOS, user-level here)
  home.packages =
    (import ../packages/system-packages.nix { inherit pkgs; }) ++
    (import ../packages/home-packages.nix { inherit pkgs; }) ++
    (with pkgs; [
      # --- macOS-only packages
      btop
      gawk
      devenv-init
    ]);

  # --- override the shared module's settings so HM doesn't create a read-only
  # --- Nix store symlink for starship.toml. Instead, use an activation script
  # --- to place a writable copy. This prevents tools like dda that
  # --- copy+overwrite starship.toml (preserving permissions) from failing
  # --- with PermissionError on the read-only Nix store source (mode 444).
  programs.starship.settings = lib.mkForce {};
  home.activation.starshipConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    install -m 644 ${../configs/starship.toml} ${config.home.homeDirectory}/.config/starship.toml
  '';

  # --- home manager state version
  home.stateVersion = "25.11";

  # --- home manager self management
  programs.home-manager.enable = true;
}
