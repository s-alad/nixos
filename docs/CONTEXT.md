# CONTEXT.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Context

Multi-system Nix flake supporting:
- **NixOS** (ThinkPad P1 Gen 8, hostname: `salad`, user: `salad`) — full NixOS + home-manager as NixOS module
- **macOS** (Datadog work laptop, config: `datadog`) — standalone home-manager only (no nix-darwin, due to IT restrictions). Username lives in `secrets.nix` (gitignored).

Both machines share the same shell stack (zsh, starship, oh-my-zsh, eza, zoxide) via shared home-manager modules.

## Build Commands

```bash
# NixOS (on the ThinkPad, from /etc/nixos)
nh os switch path:/etc/nixos          # alias: ns
nh os switch path:/etc/nixos -u       # alias: nu (with update)
sudo nixos-rebuild switch             # alias: sn

# macOS (standalone home-manager via nh)
nh home switch ~/salad/nixos -c datadog             # alias: hms
nix flake update && nh home switch ... -c datadog   # alias: hmu
home-manager switch --flake ~/salad/nixos#datadog -b backup  # alias: hmb (with backup, use if Ansible conflicts)

# First-time macOS activation (home-manager not in PATH yet)
nix run home-manager/master -- switch --flake ~/salad/nixos#datadog -b backup

# Preview what `ns` would change vs the running system (alias: nd)
nix store diff-closures /run/current-system "$(nix build --no-link --print-out-paths path:/etc/nixos#nixosConfigurations.salad.config.system.build.toplevel)"
```

## Architecture

```
flake.nix                              # Two outputs: nixosConfigurations.salad + homeConfigurations.datadog
├── hosts/
│   └── salad/                         # only NixOS host (datadog is standalone home-manager — no host dir)
│       ├── configuration.nix          # NixOS system config (boot, hardware, nvidia, services, packages)
│       └── hardware-configuration.nix
├── home/
│   ├── salad.nix                      # NixOS HM entrypoint (shared imports + NixOS-specific + Linux-only packages)
│   └── datadog.nix                    # macOS HM entrypoint (shared imports + macOS-specific + macOS-only packages)
├── packages/                          # Package lists (plain Nix functions, not modules)
│   ├── system-packages.nix            #   system-level on NixOS, home-level on macOS
│   └── home-packages.nix              #   home-level on both
├── modules/
│   ├── system/                        # NixOS system-level modules (imported by configuration.nix)
│   │   ├── zsh.nix                    # System shell registration (environment.shells)
│   │   ├── wifi-offload-fix.nix       # BE201 wifi TSO/GSO offload workaround (see wifi.md)
│   │   └── ...                        # boot, graphics, desktop, networking, minecraft, sst, nixbuild, locale, fonts, fingerprint, containers, nix-ld, steam, vpn, etc.
│   └── home/
│       ├── common/                    # Shared HM modules (imported by both machines)
│       │   ├── zsh.nix                # Shell: oh-my-zsh + common aliases (eza, zoxide) + XDG dotDir
│       │   ├── starship.nix           # Prompt: imports configs/starship.toml
│       │   ├── fastfetch.nix          # Custom fastfetch theme + ASCII art
│       │   ├── fonts.nix              # Shared fonts (user-level on darwin; NixOS uses system fonts.packages)
│       │   ├── git.nix                # Shared git base (identity from secrets.nix, defaultBranch)
│       │   ├── pass.nix               # password-store (pass)
│       │   ├── xdg-dotfiles.nix       # Shared XDG-relocated REPL history (NODE_REPL_HISTORY)
│       │   └── direnv.nix             # Shared direnv + nix-direnv config
│       ├── linux/                     # NixOS HM overrides (imported by home/salad.nix)
│       │   ├── zsh.nix                # NixOS aliases (ns, nu, ua, sn, nd)
│       │   ├── xdg-tool-homes.nix     # Relocate GOPATH/ANDROID/npm/etc. into XDG dirs
│       │   └── git.nix                # SSH signing (format=ssh), safe.directory
│       └── darwin/                    # macOS HM overrides (imported by home/datadog.nix)
│           ├── zsh.nix                # hms/hmu/hmb aliases, corporate.zsh sourcing
│           └── git.nix                # dd-gitsign, corporate hooks, delta, URL rewrites
├── configs/starship.toml              # Shared starship prompt config
├── scripts/devenv-init.sh             # Scaffolds devenv projects in .nixdev/
├── lib/lightdm-background.nix
├── lib/devenv-init.nix                # Shared devenv-init wrapper (both entrypoints)
├── packages/fonts.nix                 # Shared font set (system on NixOS, home on darwin)
├── assets/darkcarpet.jpeg
├── assets/face.png                    # Login avatar (home.file.".face")
└── secrets.nix                        # Gitignored — different per machine (personal vs work identity)
```

## Module Sharing Pattern

Each subsystem (zsh, git, starship) follows the same pattern:

```
modules/home/common/<x>.nix      shared base (both machines)
modules/home/linux/<x>.nix       NixOS-specific overrides
modules/home/darwin/<x>.nix      macOS-specific overrides
```

## Package Sharing Pattern

Packages are plain Nix lists (not modules) so each package is defined once:

- **`packages/system-packages.nix`** — `environment.systemPackages` on NixOS, `home.packages` on macOS. Core tools: vim, git, gh, go, gnumake, ripgrep, eza, jq, wget, nh, devenv, fastfetch, cowsay, lolcat, tree, tlrc, mitmproxy, postgresql, xclip. (zoxide/fzf/bat/direnv are NOT here — they come with shell integration from home-manager `programs.*` in `modules/home/common`.)
- **`packages/home-packages.nix`** — `home.packages` on both. Cloud/ops: awscli2, google-cloud-sdk, azure-cli, eksctl, kind, kubectx, kubernetes-helm, skaffold, bazelisk
- **`home/salad.nix`** inline — Linux-only home packages (GUI apps: thunderbird, bottles, discord, slack, brave, etc.)
- **`home/datadog.nix`** inline — macOS-only home packages (btop, gawk)
- **`hosts/salad/configuration.nix`** inline — NixOS-only system packages (efibootmgr, nvidia tools, btop-cuda, etc.)

To share a package: move it from the platform-specific location into the appropriate `packages/*.nix` list, and remove it from where it was. Never duplicate — each package lives in exactly one place. Always verify the nixpkgs package name exists with `nix eval nixpkgs#<name>.name` before adding.

## secrets.nix

Gitignored. Each machine has its own copy with different values:

```nix
{
  gitUserName = "...";
  gitUserEmail = "...";
  gitSigningKey = "...";    # only used by NixOS (modules/home/linux/git.nix)
  macUser = "...";           # macOS username, used by home/datadog.nix
}
```

- Shared `modules/home/common/git.nix` reads `gitUserName` and `gitUserEmail`
- NixOS `modules/home/linux/git.nix` reads `gitSigningKey` for SSH signing
- macOS signing is handled by dd-gitsign (via `~/.config/gitsign/gitconfig` include), not secrets.nix
- On a fresh clone, must run `git add --force --intent-to-add secrets.nix` so Nix flakes can see it

## macOS Corporate Coexistence

- `~/.config/zsh/corporate.zsh` — not Nix-managed, contains Datadog/corporate shell config
- Extracted from the original `~/.zshrc` (Ansible block, dd-gitsign, pyenv, rbenv, nvm, SCFW, work aliases, Homebrew paths)
- `modules/home/darwin/zsh.nix` sources it via `programs.zsh.initContent`
- HM generates `~/.zshrc` → oh-my-zsh + starship + Nix tools first, then corporate config layers on top
- Corporate PATH additions (Homebrew, pyenv, etc.) prepend to PATH, so corporate tools take precedence over Nix duplicates
- If Ansible rewrites `~/.zshrc`, use `hmb` alias to re-backup and take over

## macOS Pre-Activation Checklist

Before first `home-manager switch` on macOS:

1. **Install Nix**: `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
2. **Create `secrets.nix`** with work identity (gitUserName, gitUserEmail, gitSigningKey, macUser)
3. **Track secrets.nix**: `git add --force --intent-to-add secrets.nix`
4. **Extract corporate .zshrc** into `~/.config/zsh/corporate.zsh` (everything except oh-my-zsh setup and starship init)
5. **Activate**: `nix run home-manager/master -- switch --flake ~/salad/nixos#datadog -b backup`

## What HM Manages on macOS

| File | Action | Backup |
|------|--------|--------|
| `~/.zshrc` | Replaced (corporate config sourced from `~/.config/zsh/corporate.zsh`) | `.zshrc.backup` |
| `~/.gitconfig` | Replaced (dd-gitsign included via `~/.config/gitsign/gitconfig`) | `.gitconfig.backup` |
| `~/.config/starship.toml` | Replaced (same config as NixOS) | `starship.toml.backup` |
| `~/.config/fastfetch/config.jsonc` | Replaced with custom theme | `config.jsonc.backup` |
| `~/.zprofile` | NOT managed — keeps Homebrew shellenv | — |
| `~/.oh-my-zsh/` | NOT deleted — HM uses its own copy from Nix store | — |
| `~/.config/gitsign/gitconfig` | NOT managed — referenced via git include | — |
| `~/.config/zsh/corporate.zsh` | NOT managed — manually maintained corporate config | — |

## Homebrew Migration Status

Aggressively migrated from 175+ Homebrew packages. Remaining `brew leaves`:

**Keep in Homebrew:**
- `aws-vault` — corporate AWS auth
- `coreutils` — corporate zsh hardcodes Homebrew path
- `pyenv`, `rbenv`, `tfenv` — version managers sourced by corporate zsh
- `mole` — SSH tunnel tool (not in nixpkgs)
- `cmake` — build tool (kept in Homebrew by choice)
- `bash` — newer bash than macOS built-in
- `fontconfig` — system lib dependency
- All `datadog/tap/*` — corporate tools
- `font-meslo-lg-nerd-font` — Nerd Font for Terminal.app (MesloLGS Nerd Font, size 14)
- All `datadog/tap/*` casks and `dd-*`, `dda`, `ddcall`, `ddr`, `ddtool`, `docker-desktop`, `font-hack-nerd-font`, etc.

**Moved to Nix:** bat, btop, cowsay, eza, fzf, gawk, gcc, gh, git, gnumake, go, jq, lolcat, fastfetch, nh, ripgrep, tree, tlrc, vim, wget, zoxide, awscli2, azure-cli, bazelisk, eksctl, google-cloud-sdk, kind, kubectx, kubernetes-helm, skaffold

**Still moveable:** `gnupg`, `pre-commit`, `pipx` (scfw depends on it — may need to stay), `pulumi` (verify not a Datadog fork)

## Fonts Caveat

HM-installed fonts use fontconfig. macOS terminals (Terminal.app, iTerm2) use Core Text and won't see them. Keep Nerd Fonts installed via Homebrew cask. Current setup: `font-meslo-lg-nerd-font` — Terminal.app set to "MesloLGS Nerd Font" size 14 (same look as the previous Meslo LG L Powerline font, but with full Nerd Font icon support for eza/starship).

## Important Notes

- `nix-command` and `flakes` experimental features are enabled
- `nixpkgs.config.allowUnfree = true` on both platforms (explicit in `home/datadog.nix` for standalone HM)
- `home.backupFileExtension` only works in NixOS module integration, not standalone HM — use `-b backup` CLI flag (via `hmb` alias)
- `nh home switch` does NOT support `-b` flag — use `hmb` (raw home-manager) when backups are needed
- `nix flake check` fails on macOS without `secrets.nix` in git index — use `hms` directly instead
- HM option naming differs from NixOS: `autosuggestion` (HM, singular) vs `autosuggestions` (NixOS, plural), `oh-my-zsh` (HM) vs `ohMyZsh` (NixOS), `settings` (HM) vs `extraConfig` (deprecated)
- `initExtra` is deprecated in newer HM — use `initContent` instead
- NixOS system-level modules are in `modules/system/`, NixOS HM overrides are in `modules/home/linux/` — don't mix them
- Always verify nixpkgs package names with `nix eval nixpkgs#<name>.name` before adding (e.g., `helm` is NOT Kubernetes Helm — use `kubernetes-helm`)
- Never add new packages without explicitly telling the user — only move existing ones
- Cinnamon is **no longer pinned to stable** — runs from nixos-unstable. The old `packageOverrides` pin didn't catch individual top-level packages like `cinnamon-settings-daemon`.

## TODO

- Eventually sanitize repo (rewrite git history to scrub PII from old commits via `git filter-repo`)
- Share cross-platform CLI tools from NixOS to macOS (tmux, helix, glow, unzip, p7zip, fastfetch, uv, htop, ffmpeg, devenv, codex, chafa, w3m, dysk)
- Move remaining Homebrew packages to Nix (gnupg, pre-commit, pulumi)
- Consider managing `gh` CLI config via `programs.gh`
- Clean up duplicate Go version managers (`~/.g/` — Nix already provides Go)
- Add `nil` LSP to the devShell (devShells output already exists with nh/nixfmt-rfc-style/nix-diff/git)
