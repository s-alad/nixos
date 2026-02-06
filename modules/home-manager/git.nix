{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  programs.git = {
    enable = true;

    userName = secrets.gitUserName;
    userEmail = secrets.gitUserEmail;

    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
