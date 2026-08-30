{ pkgs }:

# Shared `devenv-init` wrapper script (used by both the NixOS host and the
# standalone darwin home-manager config). Path resolves relative to lib/.
pkgs.writeShellScriptBin "devenv-init" (builtins.readFile ../scripts/devenv-init.sh)
