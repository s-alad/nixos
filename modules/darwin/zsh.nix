{ config, pkgs, lib, ... }:

{
  # macOS-specific zsh overrides (base config in modules/home-manager/zsh.nix)

  programs.zsh.shellAliases = {
    hms = "nh home switch ~/salad/nixos -c datadog";
    hmu = "nix flake update ~/salad/nixos && nh home switch ~/salad/nixos -c datadog";
    hmsb = "home-manager switch --flake ~/salad/nixos#datadog -b backup";  # use if Ansible rewrites .zshrc
  };

  # --- source corporate/Datadog zsh config after nix-managed config
  # Before first activation: extract corporate blocks from ~/.zshrc into this file.
  # Include everything EXCEPT oh-my-zsh setup and starship init (HM handles those).
  programs.zsh.initContent = ''
    if [[ -f "$HOME/.config/zsh/corporate.zsh" ]]; then
      source "$HOME/.config/zsh/corporate.zsh"
    fi
  '';
}
