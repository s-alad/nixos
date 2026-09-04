{ config, ... }:

# shell-only XDG relocations. GUI-visible tool homes (GOPATH, npm, android,
# dotnet, nv) live in modules/system/session-env.nix.
{
  home.sessionPath = [ "${config.home.homeDirectory}/.local/share/go/bin" ];

  home.sessionVariables = {
    PSQL_HISTORY = "${config.xdg.stateHome}/psql/history";              # ~/.psql_history
    PULUMI_HOME  = "${config.xdg.dataHome}/pulumi";                     # ~/.pulumi
    VIMINIT      = "set viminfo+=n${config.xdg.stateHome}/vim/viminfo"; # ~/.viminfo
    HISTFILE     = "${config.xdg.stateHome}/bash/history";              # ~/.bash_history (zsh sets its own)
    WGETRC       = "${config.xdg.configHome}/wgetrc";                   # ~/.wget-hsts via hsts-file below
    # NODE_REPL_HISTORY -> modules/home/common/xdg-dotfiles.nix
  };

  xdg.configFile."wgetrc".text = "hsts-file = ${config.xdg.dataHome}/wget-hsts\n";
}
