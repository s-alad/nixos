{ config, pkgs, lib, ... }:

{
  # NixOS-specific git overrides (base config in modules/home-manager/git.nix)

  programs.git.signing = {
    key = (import ../../../secrets.nix).gitSigningKey;
    signByDefault = true;
  };

  programs.git.extraConfig = {
    gpg.format = "ssh";
    safe.directory = "/etc/nixos";
  };
}
