{ config, pkgs, lib, ... }:

{
  environment.shells = with pkgs; [ zsh ];

  programs.zsh = {
    enable = true;

    enableCompletion = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "eza -lh --group-directories-first --icons --git";
      la = "eza -lah --group-directories-first --icons";
      ls = "eza --group-directories-first --icons";
      lt = "eza --tree --level=2 --group-directories-first --icons";
      ns = "nh os switch path:/etc/nixos";
      nu = "nh os switch path:/etc/nixos -u";
      sn = "sudo nixos-rebuild switch";
      un = "sudo nix-channel --update && nix-channel --update && sudo nixos-rebuild switch";
      cd = "z";
    };

    ohMyZsh = {
      enable = true;
      plugins = [
        "git"
        "aws"
        "gh"
        "golang"
        "kubectl"
        "npm"
        "ssh"
        "zoxide"
        "aliases"
      ];
    };

    histSize = 10000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "HIST_IGNORE_ALL_DUPS"
    ];

    # --- initialize starship prompt
    interactiveShellInit = ''
      eval "$(starship init zsh)"
    '';
  };
}
