{ config, pkgs, ... }:

{
  imports = [
    ../modules/home-manager/zsh.nix
    ../modules/home-manager/starship.nix
    ../modules/home-manager/fastfetch.nix
    ../modules/home-manager/fonts.nix
    ../modules/home-manager/git.nix
    ../modules/home-manager/direnv.nix
    ../modules/home-manager/pass.nix
    # --- NixOS-specific
    ../modules/nixos/home/zsh.nix
    ../modules/nixos/home/git.nix
  ];

  home.username = "salad";
  home.homeDirectory = "/home/salad";

  xdg.enable = true;

  # --- home manager state version
  home.stateVersion = "25.11";

  # --- Go toolchain paths (moved from configuration.nix environment.interactiveShellInit)
  home.sessionVariables.GOPATH = "${config.home.homeDirectory}/.local/share/go";
  home.sessionPath = [ "${config.home.homeDirectory}/.local/share/go/bin" ];

  # --- desktop wallpaper, reproducible from repo asset (was undeclared ~/Pictures/darkcarp.jpeg)
  home.file."Pictures/darkcarp.jpeg".source = ../assets/darkcarpet.jpeg;

  home.packages = (import ../modules/shared/home-packages.nix { inherit pkgs; }) ++ (with pkgs; [
    thunderbird
    # (bottles.override { removeWarningPopup = true; })
    discord
    slack
    opencode
    claude-code
    code-cursor
    brave
    qbittorrent
    burpsuite
    zoom-us
    mongodb-compass
    obsidian
    postman
    # redisinsight  # broken in nixpkgs - nix-prefetch-git missing in sandbox
    google-chrome
    element-desktop
    gimp3
    gitfetch
    libreoffice
    prismlauncher
    cbonsai
    cmatrix
    sl
    oneko
    unityhub
    android-studio
    watchman
    mapscii
    monero-cli
    monero-gui
    framesh
    session-desktop
    cloudflared
    telegram-desktop
  ]);

  # --- home manager self management
  programs.home-manager.enable = true;
}
