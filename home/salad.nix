{ config, pkgs, ... }:

{
  imports = [
    ../modules/home/common/zsh.nix
    ../modules/home/common/starship.nix
    ../modules/home/common/fastfetch.nix
    ../modules/home/common/fonts.nix
    ../modules/home/common/git.nix
    ../modules/home/common/direnv.nix
    ../modules/home/common/pass.nix
    # --- NixOS-specific
    ../modules/home/linux/zsh.nix
    ../modules/home/linux/git.nix
  ];

  home.username = "salad";
  home.homeDirectory = "/home/salad";

  xdg.enable = true;

  # --- home manager state version
  home.stateVersion = "25.11";

  # --- Go toolchain paths (moved from configuration.nix environment.interactiveShellInit)
  home.sessionPath = [ "${config.home.homeDirectory}/.local/share/go/bin" ];

  # --- relocate tool homes / REPL histories off $HOME root into XDG dirs (1b).
  # forward-only: tools read these at startup and write to the new path; existing
  # ~/.npm, ~/.android, etc. must be moved/deleted once (after a fresh relogin).
  home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/.local/share/go";

    NPM_CONFIG_CACHE  = "${config.xdg.cacheHome}/npm";        # ~/.npm (8G)   -> ~/.cache/npm
    ANDROID_USER_HOME = "${config.xdg.dataHome}/android";     # ~/.android (9G AVDs) -> ~/.local/share/android
    ANDROID_HOME      = "${config.home.homeDirectory}/Android/Sdk";  # explicit SDK location
    ANDROID_SDK_ROOT  = "${config.home.homeDirectory}/Android/Sdk";
    DOTNET_CLI_HOME             = "${config.xdg.dataHome}/dotnet";   # ~/.dotnet -> XDG
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";      # ~/.nv     -> ~/.cache/nv
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/history";      # ~/.node_repl_history
    PSQL_HISTORY      = "${config.xdg.stateHome}/psql/history";      # ~/.psql_history
    PULUMI_HOME       = "${config.xdg.dataHome}/pulumi";            # ~/.pulumi
    VIMINIT           = "set viminfo+=n${config.xdg.stateHome}/vim/viminfo";  # ~/.viminfo
  };

  # --- desktop wallpaper, reproducible from repo asset (was undeclared ~/Pictures/darkcarp.jpeg)
  home.file."Pictures/darkcarp.jpeg".source = ../assets/darkcarpet.jpeg;

  # --- login avatar, reproducible from repo asset (AccountsService/LightDM read ~/.face)
  home.file.".face".source = ../assets/face.png;

  home.packages = (import ../packages/home-packages.nix { inherit pkgs; }) ++ (with pkgs; [
    thunderbird
    # (bottles.override { removeWarningPopup = true; })
    discord
    stremio-linux-shell
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
