{ config, pkgs, lib, ... }:

{
  # macOS-specific zsh overrides (base config in modules/home-manager/zsh.nix)

  programs.zsh.shellAliases = {
    hms = "nh home switch ~/salad/nixos -c datadog";
    hmu = "nix flake update ~/salad/nixos && nh home switch ~/salad/nixos -c datadog";
    hmb = "home-manager switch --flake ~/salad/nixos#datadog -b backup";  # use if Ansible rewrites .zshrc
    dab = "dda inv agent.clean && dda inv rtloader.clean && dda inv agent.build";
    gpu = "git push -u origin HEAD";
    abd = "dda inv agent.build";
    aru = "dda inv agent.run -c dev/dist";
    sec = "./bin/agent/agent secret -c dev/dist/datadog.yaml";
  };

  # --- source corporate/Datadog zsh config after nix-managed config
  # Before first activation: extract corporate blocks from ~/.zshrc into this file.
  # Include everything EXCEPT oh-my-zsh setup and starship init (HM handles those).
  programs.zsh.initContent = ''
    dog() { ./bin/agent/agent "$@" -c dev/dist/datadog.yaml; }

    if [[ -f "$HOME/.config/zsh/corporate.zsh" ]]; then
      source "$HOME/.config/zsh/corporate.zsh"
    fi
  '';
}
