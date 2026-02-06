{ pkgs }:

with pkgs; [
  vim
  lolcat

  # --- shell dependencies (required for zsh aliases and plugins to work)
  eza       # aliased as ls/ll/la/lt
  zoxide    # aliased as cd
  fzf       # fuzzy finder

  # --- dev tools
  git
  gh
  go
  jq
  wget
  gnumake
  ripgrep
  bat
  neofetch
  cowsay
]
