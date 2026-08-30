{ ... }:

let
  flakePath = "/etc/nixos";
in
{
  # NixOS-specific zsh overrides (base config, incl. dotDir, in modules/home/common/zsh.nix)

  programs.zsh.shellAliases = {
    ns = "nh os switch path:${flakePath}";
    nb = "nh os boot path:${flakePath}"; # activate on next reboot - use for big jumps (ns restarts services live and can kill the session)
    nu = "nh os switch path:${flakePath} -u";
    ua = "nix flake update nixpkgs home-manager nixpkgs-stable --flake ${flakePath} && nh os switch path:${flakePath}";
    sn = "sudo nixos-rebuild switch";
    nd = ''nix store diff-closures /run/current-system "$(nix build --no-link --print-out-paths path:${flakePath}#nixosConfigurations.salad.config.system.build.toplevel)"'';
  };
}
