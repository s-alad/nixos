{ config, pkgs, lib, ... }:

{
  # --- system-level zsh (register as valid shell)
  # shell config (aliases, oh-my-zsh, etc.) is in modules/home/common/zsh.nix
  environment.shells = with pkgs; [ zsh ];
  programs.zsh.enable = true;
}
