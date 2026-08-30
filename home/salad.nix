{ pkgs, ... }:

{
  imports = [
    ../modules/home/common/zsh.nix
    ../modules/home/common/starship.nix
    ../modules/home/common/fastfetch.nix
    ../modules/home/common/fonts.nix
    ../modules/home/common/git.nix
    ../modules/home/common/direnv.nix
    ../modules/home/common/pass.nix
    ../modules/home/common/xdg-dotfiles.nix
    ../modules/home/linux/zsh.nix
    ../modules/home/linux/git.nix
    ../modules/home/linux/xdg-tool-homes.nix
    ../modules/home/linux/cinnamon-applets.nix
    ../modules/home/linux/dconf.nix
  ];

  home.username = "salad";
  home.homeDirectory = "/home/salad";

  xdg.enable = true;

  # --- home manager state version
  home.stateVersion = "25.11";

  # --- desktop wallpape
  home.file."Pictures/darkcarp.jpeg".source = ../assets/darkcarpet.jpeg;

  # --- login avatar
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
    # session-desktop  # 2026-08-04: unbuildable on both channels + uncached
    # (unstable 1.18.0 pnpm integrity bug; stable 1.17.5 better-sqlite3 vs V8).
    # See overlays/failure.nix. Re-enable once upstream builds again.
    cloudflared
    telegram-desktop
  ]);

  # --- home manager self management
  programs.home-manager.enable = true;
}
