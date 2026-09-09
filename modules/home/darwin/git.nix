{ config, pkgs, lib, ... }:

{
  # macOS-specific git overrides (shared config in modules/home/common/git.nix)

  launchd.agents.load-github-ssh-keys = {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.writeShellScript "load-github-ssh-keys" ''
          /usr/bin/ssh-add --apple-use-keychain "${config.home.homeDirectory}/.ssh/id_ed25519" >/dev/null 2>&1
          /usr/bin/ssh-add "${config.home.homeDirectory}/.ssh/id_ed25519_ddoghq" >/dev/null 2>&1
        ''}"
      ];
      ProcessType = "Background";
      RunAtLoad = true;
    };
  };

  programs.git.settings = {
    core = {
      hooksPath = "/usr/local/dd/global_hooks";
      editor = "code --wait";
      pager = "delta";
    };
    url."git@github.com:" = {
      insteadOf = "https://github.com/";
    };
    tag.forceSignAnnotated = true;
    interactive.diffFilter = "delta --color-only";
    delta.navigate = true;
    merge.conflictStyle = "zdiff3";
  };

  home.packages = with pkgs; [
    delta
  ];
}
