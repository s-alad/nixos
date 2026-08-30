{ pkgs }:

with pkgs; [
  vim
  lolcat
  cowsay
  tree
  tlrc

  # --- shell dependencies (required for zsh aliases and plugins to work)
  eza       # aliased as ls/ll/la/lt
  # zoxide / fzf / bat provided with shell integration by home-manager programs.* (modules/home/common)

  # --- nix tools
  nh
  devenv

  # --- dev tools
  git
  gh
  go
  jq
  wget
  gnumake
  ripgrep
  fastfetch
  # gnupg provided by programs.gnupg.agent (modules/system/gpg-ssh.nix)
  lsof
  mitmproxy
  postgresql
  xclip
]
