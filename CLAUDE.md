# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Context

Multi-system Nix flake supporting:
- **NixOS** (ThinkPad P1 Gen 8, hostname: `salad`) — full NixOS + home-manager as NixOS module
- **macOS** (Datadog work laptop, config: `datadog`) — standalone home-manager only (no nix-darwin)

Both machines share the same shell stack (zsh, starship, oh-my-zsh, eza, zoxide) via shared home-manager modules.

## Build Commands

```bash
# NixOS (on the ThinkPad, from /etc/nixos)
nh os switch path:/etc/nixos          # alias: ns
nh os switch path:/etc/nixos -u       # alias: nu (with update)
sudo nixos-rebuild switch             # alias: sn

# macOS (standalone home-manager)
home-manager switch --flake ~/salad/nixos#datadog   # alias: hms

# First-time macOS activation (home-manager not in PATH yet)
nix run home-manager/master -- switch --flake ~/salad/nixos#datadog

# Compare NixOS configs between commits (from /etc/nixos)
./compare.sh                          # HEAD~1 vs HEAD
./compare.sh <commit1> <commit2>
```

## Architecture

```
flake.nix                              # Two outputs: nixosConfigurations.salad + homeConfigurations.datadog
├── hosts/
│   ├── salad/
│   │   ├── configuration.nix          # NixOS system config (boot, hardware, nvidia, services, packages)
│   │   └── hardware-configuration.nix
│   └── datadog/                       # Reserved for future nix-darwin
├── home/
│   ├── salad.nix                      # NixOS HM entrypoint (shared imports + NixOS aliases + Linux-only packages)
│   └── datadog.nix                    # macOS HM entrypoint (shared imports + corporate zsh + macOS-only packages)
├── modules/
│   ├── shared/                        # Package lists (plain Nix lists, not modules)
│   │   ├── system-packages.nix        #   system-level on NixOS, home-level on macOS
│   │   └── home-packages.nix          #   home-level on both
│   ├── home-manager/                  # Shared HM modules (imported by both machines)
│   │   ├── zsh.nix                    # Shell: oh-my-zsh + common aliases (eza, zoxide)
│   │   ├── starship.nix              # Prompt: imports configs/starship.toml
│   │   ├── neofetch.nix              # Custom neofetch theme + ASCII art
│   │   ├── fonts.nix                 # Nerd fonts, Roboto, etc.
│   │   └── git.nix                   # NixOS personal git (uses secrets.nix)
│   ├── darwin/                        # macOS-specific modules
│   │   └── git.nix                   # Work git (dd-gitsign, Datadog identity)
│   └── nixos/                         # NixOS-only system modules
│       ├── zsh.nix                    # System shell registration (environment.shells)
│       ├── starship.nix              # System starship package
│       └── ...                        # locale, fonts, fingerprint, containers, nix-ld, steam, vpn, etc.
├── configs/starship.toml              # Shared starship prompt config
├── scripts/devenv-init.sh             # Scaffolds devenv projects in .nixdev/
├── lib/lightdm-background.nix
└── assets/darkcarpet.jpeg
```

### Package Sharing Pattern

Packages are split into shared lists (plain Nix functions) so each package is defined once:

- **`modules/shared/system-packages.nix`** — system-level on NixOS (`environment.systemPackages`), home-level on macOS (`home.packages`). For tools you want everywhere.
- **`modules/shared/home-packages.nix`** — home-level on both machines (`home.packages`). For user tools shared across both.
- **`home/salad.nix`** inline — Linux-only home packages (GUI apps like thunderbird, bottles, etc.)
- **`home/datadog.nix`** inline — macOS-only home packages
- **`hosts/salad/configuration.nix`** inline — NixOS-only system packages (efibootmgr, nvidia tools, etc.)

To share a new package: move it from the platform-specific location into the appropriate `modules/shared/*.nix` list.

### Key Design Decisions

- **Shared shell config**: `modules/home-manager/zsh.nix` and `starship.nix` are imported by both `home/salad.nix` and `home/datadog.nix`. Host-specific aliases are added in the respective `home/*.nix` files.
- **secrets.nix** is gitignored, holds personal git identity — only used by `modules/home-manager/git.nix` (NixOS). The macOS config uses `modules/darwin/git.nix` with dd-gitsign instead (no secrets.nix dependency).
- **Corporate coexistence** (macOS): `home/datadog.nix` sources `~/.config/zsh/corporate.zsh` via `initExtra` for Datadog/Ansible-managed env vars, SCFW, pyenv, rbenv, nvm, etc. This file is not Nix-managed.
- **Shell stack**: zsh + oh-my-zsh + starship + zoxide (`cd`=`z`) + eza (`ls`/`ll`/`la`/`lt`) + direnv/devenv
- **devenv-init**: custom script packaged as a derivation that scaffolds `devenv` projects into `.nixdev/` subdirs

## macOS Pre-Activation Checklist

Before first `home-manager switch` on macOS:

1. **Install Nix**: `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
2. **Extract corporate .zshrc** into `~/.config/zsh/corporate.zsh`:
   - Copy lines 15-107 from `~/.zshrc` (everything from `# BEGIN ANSIBLE MANAGED BLOCK` through end of file)
   - Exclude: oh-my-zsh setup (lines 1-7) and `eval "$(starship init zsh)"` (line 11) — HM handles those
3. **Activate**: `nix run home-manager/master -- switch --flake ~/salad/nixos#datadog`

### What HM Takes Over on macOS

| File | Action | Backup |
|------|--------|--------|
| `~/.zshrc` | Replaced (corporate config sourced from `~/.config/zsh/corporate.zsh`) | `.zshrc.backup` |
| `~/.gitconfig` | Replaced (dd-gitsign included via `~/.config/gitsign/gitconfig`) | `.gitconfig.backup` |
| `~/.config/starship.toml` | Replaced (minor color differences from existing) | `starship.toml.backup` |
| `~/.config/neofetch/config.conf` | Replaced with custom theme | `config.conf.backup` |
| `~/.zprofile` | Not managed — keeps Homebrew shellenv + privilegesalias | — |
| `~/.oh-my-zsh/` | Not deleted — HM uses its own copy from Nix store | — |
| `~/.config/gitsign/gitconfig` | Not managed — referenced via git include | — |

## Important Notes

- `nix-command` and `flakes` experimental features are enabled
- `nixpkgs.config.allowUnfree = true` on both platforms
- NixOS git: SSH-format signing via secrets.nix
- macOS git: dd-gitsign via `~/.config/gitsign/gitconfig` include
- The `compare.sh` script is NixOS-only (requires `nixos-rebuild`)
- macOS user is `saad.naji`, NixOS user is `salad`
- `nix flake check` will fail on macOS if `secrets.nix` doesn't exist (NixOS git.nix imports it). Use `home-manager switch --flake ...#datadog` directly instead.
