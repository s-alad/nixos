# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Context

Multi-system Nix flake supporting:
- **NixOS** (ThinkPad P1 Gen 8, hostname: `salad`, user: `salad`) — full NixOS + home-manager as NixOS module
- **macOS** (Datadog work laptop, config: `datadog`, user: `saad.naji`) — standalone home-manager only (no nix-darwin, due to IT restrictions)

Both machines share the same shell stack (zsh, starship, oh-my-zsh, eza, zoxide) via shared home-manager modules.

## Build Commands

```bash
# NixOS (on the ThinkPad, from /etc/nixos)
nh os switch path:/etc/nixos          # alias: ns
nh os switch path:/etc/nixos -u       # alias: nu (with update)
sudo nixos-rebuild switch             # alias: sn

# macOS (standalone home-manager)
home-manager switch --flake ~/salad/nixos#datadog -b backup   # alias: hms

# First-time macOS activation (home-manager not in PATH yet)
nix run home-manager/master -- switch --flake ~/salad/nixos#datadog -b backup

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
│   ├── salad.nix                      # NixOS HM entrypoint (shared imports + NixOS-specific + Linux-only packages)
│   └── datadog.nix                    # macOS HM entrypoint (shared imports + macOS-specific + corporate zsh)
├── modules/
│   ├── shared/                        # Package lists (plain Nix functions, not modules)
│   │   ├── system-packages.nix        #   system-level on NixOS, home-level on macOS
│   │   └── home-packages.nix          #   home-level on both
│   ├── home-manager/                  # Shared HM modules (imported by both machines)
│   │   ├── zsh.nix                    # Shell: oh-my-zsh + common aliases (eza, zoxide)
│   │   ├── starship.nix              # Prompt: imports configs/starship.toml
│   │   ├── neofetch.nix              # Custom neofetch theme + ASCII art
│   │   ├── fonts.nix                 # Nerd fonts (minus adwaita-fonts, Linux-only)
│   │   └── git.nix                   # Shared git base (identity from secrets.nix, defaultBranch)
│   ├── nixos/
│   │   ├── system/                    # NixOS system-level modules (imported by configuration.nix)
│   │   │   ├── zsh.nix               # System shell registration (environment.shells)
│   │   │   ├── starship.nix          # System starship package
│   │   │   └── ...                   # locale, fonts, fingerprint, containers, nix-ld, steam, vpn, etc.
│   │   └── home/                      # NixOS HM overrides (imported by home/salad.nix)
│   │       ├── zsh.nix               # dotDir, NixOS aliases (ns, nu, sn, un)
│   │       └── git.nix               # SSH signing, safe.directory
│   └── darwin/                        # macOS HM overrides (imported by home/datadog.nix)
│       ├── zsh.nix                   # hms alias, corporate.zsh sourcing
│       └── git.nix                   # dd-gitsign, corporate hooks, delta, URL rewrites
├── configs/starship.toml              # Shared starship prompt config
├── scripts/devenv-init.sh             # Scaffolds devenv projects in .nixdev/
├── lib/lightdm-background.nix
├── assets/darkcarpet.jpeg
└── secrets.nix                        # Gitignored — different per machine (personal vs work identity)
```

## Module Sharing Pattern

Each subsystem (zsh, git, starship) follows the same pattern:

```
modules/home-manager/<x>.nix     shared base (both machines)
modules/nixos/home/<x>.nix       NixOS-specific overrides
modules/darwin/<x>.nix            macOS-specific overrides
```

Example with zsh:
- `modules/home-manager/zsh.nix` — oh-my-zsh, common aliases (ll, la, ls, lt, cd=z), history
- `modules/nixos/home/zsh.nix` — dotDir, NixOS rebuild aliases (ns, nu, sn, un)
- `modules/darwin/zsh.nix` — hms alias, sources `~/.config/zsh/corporate.zsh`

## Package Sharing Pattern

Packages are plain Nix lists (not modules) so each package is defined once:

- **`modules/shared/system-packages.nix`** — `environment.systemPackages` on NixOS, `home.packages` on macOS
- **`modules/shared/home-packages.nix`** — `home.packages` on both machines
- **`home/salad.nix`** inline — Linux-only home packages (GUI apps: thunderbird, bottles, etc.)
- **`home/datadog.nix`** inline — macOS-only home packages
- **`hosts/salad/configuration.nix`** inline — NixOS-only system packages (efibootmgr, nvidia tools, etc.)

To share a package: move it from the platform-specific location into the appropriate `modules/shared/*.nix` list, and remove it from where it was. Never duplicate — each package lives in exactly one place.

## secrets.nix

Gitignored. Each machine has its own copy with different values:

```nix
{
  gitUserName = "...";
  gitUserEmail = "...";
  gitSigningKey = "...";    # only used by NixOS (modules/nixos/home/git.nix)
}
```

- Shared `modules/home-manager/git.nix` reads `gitUserName` and `gitUserEmail`
- NixOS `modules/nixos/home/git.nix` reads `gitSigningKey` for SSH signing
- macOS signing is handled by dd-gitsign (via `~/.config/gitsign/gitconfig` include), not secrets.nix
- On a fresh clone, must run `git add --force --intent-to-add secrets.nix` so Nix flakes can see it

## macOS Corporate Coexistence

- `~/.config/zsh/corporate.zsh` — not Nix-managed, contains Datadog/corporate shell config
- Extracted from the original `~/.zshrc` (lines 15-107: Ansible block, dd-gitsign, pyenv, rbenv, nvm, SCFW, work aliases)
- `modules/darwin/zsh.nix` sources it via `programs.zsh.initContent`
- HM generates `~/.zshrc` → oh-my-zsh + starship + Nix tools first, then corporate config layers on top
- If Ansible rewrites `~/.zshrc`, HM will conflict on next switch — re-extract to `corporate.zsh` and re-run `hms`

## macOS Pre-Activation Checklist

Before first `home-manager switch` on macOS:

1. **Install Nix**: `curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install`
2. **Create `secrets.nix`** with work identity (gitUserName, gitUserEmail, gitSigningKey)
3. **Track secrets.nix**: `git add --force --intent-to-add secrets.nix`
4. **Extract corporate .zshrc** into `~/.config/zsh/corporate.zsh` (everything except oh-my-zsh setup and starship init)
5. **Activate**: `nix run home-manager/master -- switch --flake ~/salad/nixos#datadog -b backup`

## What HM Manages on macOS

| File | Action | Backup |
|------|--------|--------|
| `~/.zshrc` | Replaced (corporate config sourced from `~/.config/zsh/corporate.zsh`) | `.zshrc.backup` |
| `~/.gitconfig` | Replaced (dd-gitsign included via `~/.config/gitsign/gitconfig`) | `.gitconfig.backup` |
| `~/.config/starship.toml` | Replaced (same config as NixOS) | `starship.toml.backup` |
| `~/.config/neofetch/config.conf` | Replaced with custom theme | `config.conf.backup` |
| `~/.zprofile` | NOT managed — keeps Homebrew shellenv | — |
| `~/.oh-my-zsh/` | NOT deleted — HM uses its own copy from Nix store | — |
| `~/.config/gitsign/gitconfig` | NOT managed — referenced via git include | — |
| `~/.config/zsh/corporate.zsh` | NOT managed — manually maintained corporate config | — |

## Homebrew Migration

Gradually replacing Homebrew packages with Nix. Process per package:
1. Add to `modules/shared/system-packages.nix` (remove from `configuration.nix` or `home/salad.nix` if it was there)
2. Run `hms` on macOS
3. Verify the Nix version works (`which <tool>` shows nix path)
4. `brew uninstall <package>`

**Keep in Homebrew** (corporate/Datadog, or Nix can't replace):
- All `dd-*` tools, `dda`, `ddcall`, `ddr`, `ddtool`, `datadog-workspaces`
- `docker-desktop`, `1password-cli`, `gcloud-cli`
- `pyenv`, `rbenv` (corporate zsh sources these)
- `aws-vault`, `helm`, `kubernetes-cli`, `eksctl`, `skaffold`, `kind`, `tfenv`, `pulumi`
- `font-hack-nerd-font` (Nix fonts don't register with macOS Core Text without nix-darwin)

## Fonts Caveat

HM-installed fonts use fontconfig. macOS terminals (iTerm2, Terminal.app) use Core Text and won't see them. Keep Homebrew `font-hack-nerd-font` and set your terminal to use "Hack Nerd Font" for icons in eza/starship.

## Important Notes

- `nix-command` and `flakes` experimental features are enabled
- `nixpkgs.config.allowUnfree = true` on both platforms (explicit in `home/datadog.nix` for standalone HM)
- `home.backupFileExtension` only works in NixOS module integration, not standalone HM — use `-b backup` CLI flag instead (baked into `hms` alias)
- `nix flake check` fails on macOS without `secrets.nix` in git index — use `hms` directly instead
- HM option naming differs from NixOS: `programs.zsh.autosuggestion` (HM, singular) vs `programs.zsh.autosuggestions` (NixOS, plural), `oh-my-zsh` (HM) vs `ohMyZsh` (NixOS), `settings` (HM) vs `extraConfig` (deprecated)
- NixOS system-level modules are in `modules/nixos/system/`, NixOS HM overrides are in `modules/nixos/home/` — don't mix them
