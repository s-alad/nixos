{ config, pkgs, lib, ... }:

{
  programs.git = {
    enable = true;

    # Use environment variables for sensitive config
    # Set these before building:
    #   export GIT_USER_NAME="your-name"
    #   export GIT_USER_EMAIL="your@email.com"
    #   export GIT_SIGNING_KEY="/path/to/key.pub"
    userName = builtins.getEnv "GIT_USER_NAME";
    userEmail = builtins.getEnv "GIT_USER_EMAIL";

    signing = {
      key = builtins.getEnv "GIT_SIGNING_KEY";
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";
      gpg.format = "ssh";
      safe.directory = "/etc/nixos";
    };
  };
}
