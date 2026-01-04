{ config, pkgs, ... }:

{
  imports = [
    ../modules/home-manager/git.nix
    ../modules/home-manager/neofetch.nix
  ];

  home.username = "salad";
  home.homeDirectory = "/home/salad";

  xdg.enable = true;

  # --- home manager state version
  home.stateVersion = "25.11";

  home.packages = with pkgs; [
    thunderbird
    (bottles.override { removeWarningPopup = true; })
    discord
    slack
    claude-code
    code-cursor
    brave
    qbittorrent
    burpsuite
    zoom-us
    mongodb-compass
    obsidian
    postman
    redisinsight
    google-chrome
    element-desktop
    gimp2
    google-cloud-sdk
    awscli2
    gitfetch
    libreoffice
    prismlauncher
    cbonsai
    cowsay
    cmatrix
    sl
    oneko
    lolcat
    unityhub
    android-studio
    watchman
    mapscii
    monero-cli
    monero-gui
    framesh
  ];

  # --- XDG user directories
  home.sessionVariables = {
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME   = "$HOME/.local/share";
    XDG_STATE_HOME  = "$HOME/.local/state";
    XDG_CACHE_HOME  = "$HOME/.cache";
  };

  # --- home manager self management
  programs.home-manager.enable = true;
}
