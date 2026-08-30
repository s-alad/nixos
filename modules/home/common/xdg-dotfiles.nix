{ config, ... }:

{
  # XDG-relocated REPL/tool history shared across platforms.
  home.sessionVariables = {
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/history";
  };
}
