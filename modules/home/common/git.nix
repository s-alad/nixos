{ config, pkgs, lib, ... }:

let
  secrets = import ../../../secrets.nix;
in
{
  programs.git = {
    enable = true;

    ignores = [
      "**/.claude/settings.local.json"
      # only affects UNTRACKED files; use `git add -f` to commit an intentional one.
      ".env"
      ".env.local"
      "*.pem"
      "*.key"
      "*.p12"
      "*.pfx"
      "id_rsa"
      "id_ed25519"
      "*.keystore"
    ];

    settings = {
      user = {
        name = secrets.gitUserName;
        email = secrets.gitUserEmail;
      };
      init.defaultBranch = "main";
      # --- cache untracked file results between runs to speed up git status
      core.untrackedCache = true;
      # --- use a background daemon to watch for changes instead of scanning the whole tree
      core.fsmonitor = true;
    };
  };
}
