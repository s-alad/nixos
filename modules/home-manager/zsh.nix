{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    # --- shared aliases (eza, zoxide)
    # host-specific aliases (ns/nu/sn/un or hms) are added in home/*.nix
    shellAliases = {
      ll = "eza -lh --group-directories-first --icons --git";
      la = "eza -lah --group-directories-first --icons";
      ls = "eza --group-directories-first --icons";
      lt = "eza --tree --level=2 --group-directories-first --icons";
      cd = "z";
    };

    oh-my-zsh = {
      enable = true;
      plugins = [
        "git"
        "aws"
        "gh"
        "golang"
        "kubectl"
        "npm"
        "ssh"
        "pass"
        "aliases"
      ];
    };

    history = {
      size = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
      ignoreAllDups = true;
    };
  };

  # zoxide: explicit shell integration (provides `z`; `cd` is aliased to `z` above).
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  # fzf: interactive Ctrl-R (history search) / Ctrl-T (file insert) / ** completion.
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
  };

  # bat: declarative `cat` replacement.
  programs.bat.enable = true;
}
