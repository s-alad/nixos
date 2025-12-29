{ config, pkgs, ... }:

{
  home.username = "salad";
  home.homeDirectory = "/home/salad";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  home.stateVersion = "25.11";

  # User packages (migrated from configuration.nix users.users.salad.packages)
  home.packages = with pkgs; [
    thunderbird
    bottles
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
  ];

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
