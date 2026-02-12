{ config, pkgs, lib, ... }:

{
  # NixOS-specific zsh overrides (base config in modules/home-manager/zsh.nix)

  programs.zsh.dotDir = "${config.xdg.configHome}/zsh";  # XDG-compliant location

  programs.zsh.shellAliases = {
    ns = "nh os switch path:/etc/nixos";
    nu = "nh os switch path:/etc/nixos -u";
    ua = "nix flake update nixpkgs home-manager nixpkgs-stable --flake /etc/nixos && nh os switch path:/etc/nixos";
    sn = "sudo nixos-rebuild switch";
    un = "sudo nix-channel --update && nix-channel --update && sudo nixos-rebuild switch";
  };
}
