{ pkgs }:

with pkgs; [
  vim
  lolcat
  cowsay
  tree
  tlrc

  # --- shell dependencies (required for zsh aliases and plugins to work)
  eza       # aliased as ls/ll/la/lt
  zoxide    # aliased as cd
  fzf       # fuzzy finder

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
  bat
  fastfetch
  # gnupg provided by programs.gnupg.agent (modules/nixos/system/gpg-ssh.nix)
  lsof
  mitmproxy
  postgresql
  xclip
]
