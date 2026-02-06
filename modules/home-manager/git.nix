{ config, pkgs, lib, ... }:

let
  secrets = import ../../secrets.nix;
in
{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = secrets.gitUserName;
        email = secrets.gitUserEmail;
      };
      init.defaultBranch = "main";
    };
  };
}
