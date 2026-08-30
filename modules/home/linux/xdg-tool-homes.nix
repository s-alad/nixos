{ config, ... }:

# Relocate tool homes / REPL histories off the $HOME root into XDG dirs (Linux host).
# forward-only: tools read these at startup and write to the new path; existing
# ~/.npm, ~/.android, etc. must be moved/deleted once (after a fresh relogin).
{
  home.sessionPath = [ "${config.home.homeDirectory}/.local/share/go/bin" ];

  home.sessionVariables = {
    GOPATH = "${config.home.homeDirectory}/.local/share/go";

    NPM_CONFIG_CACHE  = "${config.xdg.cacheHome}/npm";        # ~/.npm (8G)   -> ~/.cache/npm
    ANDROID_USER_HOME = "${config.xdg.dataHome}/android";     # ~/.android (9G AVDs) -> ~/.local/share/android
    ANDROID_HOME      = "${config.home.homeDirectory}/Android/Sdk";  # explicit SDK location
    ANDROID_SDK_ROOT  = "${config.home.homeDirectory}/Android/Sdk";
    DOTNET_CLI_HOME             = "${config.xdg.dataHome}/dotnet";   # ~/.dotnet -> XDG
    DOTNET_CLI_TELEMETRY_OPTOUT = "1";
    __GL_SHADER_DISK_CACHE_PATH = "${config.xdg.cacheHome}/nv";      # ~/.nv     -> ~/.cache/nv
    PSQL_HISTORY      = "${config.xdg.stateHome}/psql/history";      # ~/.psql_history
    PULUMI_HOME       = "${config.xdg.dataHome}/pulumi";            # ~/.pulumi
    VIMINIT           = "set viminfo+=n${config.xdg.stateHome}/vim/viminfo";  # ~/.viminfo
    # NODE_REPL_HISTORY is shared cross-platform -> modules/home/common/xdg-dotfiles.nix
  };
}
