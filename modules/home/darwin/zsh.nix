{
  config,
  pkgs,
  lib,
  ...
}:

let
  sshAgentSocket = "${config.home.homeDirectory}/.ssh/macos-agent.sock";
in
{
  # macOS-specific zsh overrides (base config in modules/home/common/zsh.nix)

  # Connect local shells that missed launchd's dynamic SSH agent environment.
  programs.zsh.envExtra = ''
    if [[ -z "$SSH_CONNECTION" && ( -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ) && -S "${sshAgentSocket}" ]]; then
      export SSH_AUTH_SOCK="${sshAgentSocket}"
    fi
  '';

  programs.zsh.shellAliases = {
    hms = "nh home switch ~/salad/nixos -c datadog";
    hmu = "nix flake update --flake ~/salad/nixos && nh home switch ~/salad/nixos -c datadog";
    hmb = "home-manager switch --flake ~/salad/nixos#datadog -b backup";
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

    # Expose Nix PATH to macOS GUI apps (VS Code, etc.) so they can find
    # binaries like go, git, etc. without needing to be launched from terminal.
    if [[ -n "$TERM_PROGRAM" ]]; then
      launchctl setenv PATH "$PATH"
    fi
  '';
}
