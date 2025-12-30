{ config, pkgs, lib, ... }:

let
  # Import secrets from local gitignored file
  secrets = import ../../secrets.nix;
in
{
  programs.git = {
    enable = true;

    signing = {
      key = secrets.gitSigningKey;
      signByDefault = true;
    };

    settings = {
      user = {
        name = secrets.gitUserName;
        email = secrets.gitUserEmail;
      };
      init.defaultBranch = "main";
      gpg.format = "ssh";
      safe.directory = "/etc/nixos";
    };
  };
}
