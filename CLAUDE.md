# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

This is a NixOS 26.05 (Yarara) installation on a **Lenovo ThinkPad P1 Gen 8** workstation with the following key hardware:

- **CPU**: Intel Core Ultra i9
- **GPU**: NVIDIA RTX PRO 2000 Blackwell (driver 595.58.03 with CUDA 13.2, open kernel modules)
- **Graphics**: Hybrid Intel/NVIDIA setup with PRIME offload mode enabled
- **Storage**: Dual SSD configuration
  - 2TB SSD running NIXOS
  - 1TB SSD running Windows
- **Security**: LUKS full-disk encryption with TPM2 auto-unlock (both root and swap)
- **Desktop**: Cinnamon with LightDM display manager
- **Boot**: Plymouth graphical splash with silent boot

## NixOS Configuration

### Flake-Based Configuration Structure

The system now uses **Nix flakes** for reproducible, version-pinned configuration:

```
/etc/nixos/
├── flake.nix                   (inputs/outputs: nixosConfigurations.salad + homeConfigurations.datadog + formatter/checks/devShells.default)
├── flake.lock                  (locked package versions)
├── secrets.nix                 (gitignored secrets file)
├── CLAUDE.md                   (this file)
├── hosts/
│   └── salad/                  (the ONLY NixOS host; datadog is standalone home-manager, not a NixOS host)
│       ├── configuration.nix   (main system config; imports modules/system/*)
│       └── hardware-configuration.nix (auto-generated, do not edit)
├── home/                       (home-manager entrypoints, keyed by config name)
│   ├── salad.nix              (NixOS user; pulled in via home-manager.users.salad in flake.nix)
│   └── datadog.nix            (standalone home-manager for the aarch64-darwin work Mac)
├── packages/                   (raw `{ pkgs }:` package LISTS — data, not modules)
│   ├── system-packages.nix    (environment.systemPackages list)
│   └── home-packages.nix      (home.packages list)
├── configs/                    (starship.toml, fastfetch.jsonc, fastfetch-ascii.txt)
├── assets/
│   └── darkcarpet.jpeg        (lightdm background image)
├── lib/
│   └── lightdm-background.nix (image processor/builder)
├── overlays/
│   └── failure.nix            (workarounds for broken-on-unstable packages)
├── scripts/
│   └── devenv-init.sh         (devShell init script)
├── docs/                       (CONTEXT.md, wifi.md, AUDIT.md)
└── modules/
    ├── system/                (NixOS SYSTEM modules — imported by hosts/salad/configuration.nix)
    │   ├── appimage.nix       (appimage runtime support)
    │   ├── containers.nix     (docker/podman)
    │   ├── fingerprint.nix    (fingerprint auth & pam)
    │   ├── fonts.nix          (system fonts)
    │   ├── gpg-ssh.nix        (gpg agent with ssh support)
    │   ├── locale.nix         (timezone & internationalization)
    │   ├── nix-ld.nix         (libraries for prebuilt binaries)
    │   ├── programs.nix       (firefox, java, adb, wireshark, obs, nh)
    │   ├── steam.nix          (steam & gamemode)
    │   ├── tailscale.nix      (tailscale mesh vpn)
    │   ├── vpn.nix            (mullvad & mozilla vpn services)
    │   ├── wifi-offload-fix.nix (BE201 wifi offload workaround)
    │   ├── yubikey.nix        (yubikey fido2/u2f support)
    │   └── zsh.nix            (system-level zsh shell configuration)
    └── home/                  (home-manager modules, split by role)
        ├── common/            (cross-platform BASE — imported by BOTH salad and datadog)
        │   ├── direnv.nix
        │   ├── fastfetch.nix
        │   ├── fonts.nix
        │   ├── git.nix        (base git config using secrets.nix)
        │   ├── pass.nix
        │   ├── starship.nix
        │   └── zsh.nix
        ├── linux/             (NixOS-only HM OVERRIDES — git signing, ns/nu/ua rebuild aliases)
        │   ├── git.nix
        │   └── zsh.nix
        └── darwin/            (macOS-only HM OVERRIDES)
            ├── git.nix
            └── zsh.nix
```

### Flake Configuration

The system uses a hybrid approach:
- **Primary**: nixos-unstable for all packages (including Cinnamon)
- **Version locking**: flake.lock ensures reproducible builds
- **Firmware stability**: `linux-firmware` is pinned to nixpkgs-stable via overlay in `/etc/nixos/flake.nix` because recent `nu` updates on nixos-unstable coincided with iwlwifi firmware timeouts, SW resets, and stuck queues on the Intel Wi-Fi 7 BE201. Pinning firmware keeps the CachyOS kernel while avoiding rapid firmware changes that can trigger freezes.

**Flake inputs:**
```nix
nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"
nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11"
nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release" (tracks release branch, locked via flake.lock)
home-manager.url = "github:nix-community/home-manager" (active - NixOS module mode)
```

**Home-manager configuration in flake:**
```nix
home-manager.useGlobalPkgs = true;
home-manager.useUserPackages = true;
home-manager.users.salad = import ./home/salad.nix;
home-manager.backupFileExtension = "backup";  # backs up conflicting files
```

### Rebuilding the System

With flakes enabled, use these commands:

```bash
# using nh (recommended)
ns                    # nh os switch path:/etc/nixos (rebuild only, no updates)
ua                    # update apps only (safe - excludes kernel)
nu                    # nh os switch path:/etc/nixos -u (updates ALL inputs including kernel -- check NVIDIA compat first)

# traditional method (still works as fallback)
sn                    # sudo nixos-rebuild switch

# manual flake rebuild
sudo nixos-rebuild switch --flake path:/etc/nixos#salad
```

**Note:** The `path:` prefix is used to include gitignored files (like `secrets.nix`) in the build without requiring `--impure` mode.

### Update Strategy (IMPORTANT)

The CachyOS kernel tracks the `release` branch in `flake.nix` and is locked to a specific commit via `flake.lock`. Running `nu` (which calls `nix flake update`) will update **all** inputs including the kernel.

| Command | What it updates | When to use |
|---------|-----------------|-------------|
| `ns` | Nothing (uses locked versions) | After editing config, adding/removing packages |
| `ua` | Apps only (nixpkgs, home-manager, nixpkgs-stable) | **Daily/weekly updates** - safe, won't touch kernel |
| `nu` | **Everything** including kernel | When ready to update all inputs (check NVIDIA compat first) |

**NVIDIA compatibility risk:**
- NVIDIA open kernel modules compile against kernel APIs
- A new CachyOS kernel bump may break the NVIDIA build if the driver hasn't been updated
- `ua` is always safe because it explicitly excludes the kernel input
- Before running `nu`, check that the latest kernel is compatible: if the build fails, your system stays on the previous working kernel

**If a kernel update via `nu` breaks NVIDIA:**
- The build fails before activation -- your running system is unaffected
- Revert by editing `flake.lock` or re-pinning the kernel with `?rev=` in `flake.nix`:
  ```nix
  nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel?rev=KNOWN_GOOD_COMMIT";
  ```
- Then run `ns` to rebuild with the pinned kernel

**Checking kernel versions:**
```bash
# What's currently locked in flake.lock
uname -r

# What the latest CachyOS release branch has
nix eval --raw 'github:xddxdd/nix-cachyos-kernel/release#packages.x86_64-linux.linux-cachyos-latest.version'

# Find commits
curl -s "https://api.github.com/repos/xddxdd/nix-cachyos-kernel/commits?sha=release&per_page=20" | jq -r '.[] | "\(.sha[:12]) \(.commit.committer.date[:10]) \(.commit.message | split("\n")[0])"'
```

**Current kernel status (as of April 2026):**
- Running: 6.19.10-cachyos
- NVIDIA 595.58.03 supports kernel 6.19 -- no compatibility issues

### Secrets Management

The system uses a gitignored `secrets.nix` file for managing sensitive configuration values:

**Location:** `/etc/nixos/secrets.nix` (gitignored, not committed to repository)

**Format:**
```nix
{
  gitUserName = "your-name";
  gitUserEmail = "your@email.com";
  gitSigningKey = "/path/to/key.pub";

  # Add more secrets as needed
  # githubSshKey = "/home/salad/.ssh/id_ed25519";
}
```

**Usage in modules:**
```nix
let
  secrets = import ../../secrets.nix;  # adjust path as needed
in
{
  # Use secrets.someValue anywhere
  programs.git.settings.user.name = secrets.gitUserName;
}
```

**How it works:**
- The `path:/etc/nixos` flake URL copies the entire git repository (including gitignored files) to the nix store
- This allows pure evaluation without `--impure` flag
- `secrets.nix` stays gitignored and won't be committed to the repository
- Any module can import and use values from `secrets.nix`

**Current usage:**
- Git configuration: username, email, and signing key (`modules/home/common/git.nix`, with NixOS overrides in `modules/home/linux/git.nix`)

### Verifying Configuration Changes

Use native Nix tooling (replaces the old `compare.sh`):

```bash
# Preview what `ns` would change vs the running system (alias: nd)
nix store diff-closures /run/current-system \
  "$(nix build --no-link --print-out-paths path:/etc/nixos#nixosConfigurations.salad.config.system.build.toplevel)"

# Is a change behavior-neutral? Compare derivation hashes (instant, no build):
nix eval --raw path:/etc/nixos#nixosConfigurations.salad.config.system.build.toplevel.drvPath

# Diff two generations package-by-package:
nix store diff-closures /nix/var/nix/profiles/system-{N,M}-link

# Does the whole flake still build?
nix flake check path:/etc/nixos
```

To compare two git commits without disturbing the live checkout, build each from a throwaway
`git worktree` (copy in the gitignored `secrets.nix`) and `nix store diff-closures` the results.

### Package Management

The system uses **home-manager as a NixOS module** for user-specific packages and configurations.

**Package locations:**
- **System-wide packages**: `environment.systemPackages` in configuration.nix
- **User packages**: `home.packages` in home.nix (managed by home-manager)

**Adding packages:**

```bash
# search for packages
nix search nixpkgs <package-name>

# for user packages: edit /etc/nixos/home.nix
# add to home.packages = with pkgs; [ ... ]

# for system packages: edit /etc/nixos/configuration.nix
# add to environment.systemPackages = with pkgs; [ ... ]

# rebuild system (rebuilds both NixOS and home-manager)
ns  # or: nh os switch /etc/nixos

# temporary shell with packages
nix-shell -p <package-name>

# update flake inputs
nix flake update /etc/nixos

# garbage collection
sudo nix-collect-garbage -d
nh clean all --keep 10       # keep last 10 generations (matches configured nh.clean policy)
```

**Home-Manager mode:**
- Running as **NixOS module** (not standalone)
- User packages installed to `/etc/profiles/per-user/salad/`
- Rebuilt automatically with `ns` or `nu` commands
- Configuration in `/etc/nixos/home/salad.nix`
- **XDG Base Directory**: enabled via `xdg.enable = true`
- **Shell integration**: `programs.zsh.enable = true` for session variable sourcing
- **File backups**: `home-manager.backupFileExtension = "backup"` prevents file clobbering

### XDG Base Directory Specification

The system follows the **XDG Base Directory** standard for organizing user files:

**Configuration:**
```nix
# In /etc/nixos/home/salad.nix
xdg.enable = true;
programs.zsh = {
  enable = true;
  dotDir = "${config.xdg.configHome}/zsh";  # XDG-compliant location
};
```

**Environment variables set:**
- `XDG_CONFIG_HOME` → `~/.config` (application configurations)
- `XDG_DATA_HOME` → `~/.local/share` (application data)
- `XDG_STATE_HOME` → `~/.local/state` (application state/logs)
- `XDG_CACHE_HOME` → `~/.cache` (temporary cache files)

**Benefits:**
- Cleaner home directory (organized into standard locations)
- Applications that respect XDG use proper directories
- Easier backup (just backup `~/.config` for configs)
- Shell configuration moved to `~/.config/zsh/` instead of `~/.zshrc`

**Shell integration:**
- Home-manager manages zsh via `programs.zsh.enable = true`
- System-level zsh config (`/etc/nixos/modules/system/zsh.nix`) still applies
- Session variables automatically sourced via home-manager
- Both system and user configs coexist peacefully

### Maintenance

- **garbage collection**: managed by nh (clean.enable = true)
- **auto-optimize store**: enabled for deduplication
- **boot generations**: `nh.clean` keeps 10 (`clean.extraArgs = "--keep 10"`) to match systemd-boot `configurationLimit = 10` (without the explicit keep, nh defaults to `--keep 1` and removes all rollback targets)
- **nix flakes**: enabled with version locking via flake.lock
- **nh**: nix helper enabled for better rebuild experience

## Hardware-Specific Configuration

### NVIDIA + Intel Hybrid Graphics

The system uses **NVIDIA PRIME Offload Mode** (not Sync Mode) for better battery life:

- Intel Arc Pro 140T iGPU: `PCI:0:2:0`
- NVIDIA RTX PRO 2000 Blackwell GPU: `PCI:1:0:0`
- Running NVIDIA driver 595.58.03 with open-source kernel modules
- Using Intel iHD for video acceleration (LIBVA_DRIVER_NAME="iHD")

### Graphics Testing

```bash
# check intel va-api
vainfo

# test opengl (intel)
glxinfo | grep "OpenGL renderer"

# test vulkan
vulkaninfo

# monitor gpu usage
nvtop

# check nvidia status
nvidia-smi
```

### Kernel and Drivers

- **kernel**: CachyOS Latest (`boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest`)
  - Currently running 6.19.10-cachyos with EEVDF scheduler
  - CachyOS kernel provides performance optimizations and latest scheduler improvements
  - Kernel tracks the `release` branch, locked via `flake.lock` (not pinned with `?rev=`)
- **nvidia drivers**: 595.58.03 stable with open kernel modules
- **intel microcode**: updates enabled
- **wifi tuning**: `power_save=0 swcrypto=1 11n_disable=8 disable_11be=1` (for stability — 11be disabled due to BE201 firmware NMI crashes)

**Available CachyOS kernel variants:**
```nix
pkgs.cachyosKernels.linuxPackages-cachyos-latest  # bleeding edge (current)
pkgs.cachyosKernels.linuxPackages-cachyos-lts     # LTS with CachyOS patches
pkgs.cachyosKernels.linuxPackages-cachyos-bore    # BORE scheduler
pkgs.cachyosKernels.linuxPackages-cachyos-eevdf   # EEVDF scheduler
pkgs.cachyosKernels.linuxPackages-cachyos-hardened # security-hardened
```

## Development Environment

### Installed Development Tools

- **Languages**: Node.js, Yarn, Go, OCaml, Rust (rustc, cargo, rustfmt, clippy, rust-analyzer), Java (JDK), Python (uv)
- **Editors**: VSCode, Cursor, Helix, Vim
- **Version Control**: Git, GitHub CLI (gh)
- **Containers**: Docker (user 'salad' is in docker group)
- **Mobile Development**: ADB enabled, Android Studio, Watchman (React Native)
- **Game Development**: Unity Hub, PrismLauncher (Minecraft)
- **System Monitoring**: btop-cuda, htop, nvtopPackages.full, lm_sensors
- **CLI Tools**: ripgrep, jq, fzf, eza, zoxide, bat, tmux, ffmpeg, starship, nh, dysk, fastfetch, mapscii
- **File Transfer**: rsync (included by default), p7zip (for archive extraction)
- **Archive Manager**: file-roller (GNOME archive manager, requires p7zip for encrypted archives)
- **Cloud**: Google Cloud SDK, AWS CLI v2
- **Database**: Redis, MongoDB Compass (RedisInsight currently broken in nixpkgs - use Flatpak if needed)
- **Media**: OBS Studio (with CUDA encoding & virtual camera)
- **Security**: Wireshark (with packet capture), Burp Suite, Seahorse, YubiKey Manager (ykman)
- **VPN**: Mullvad VPN, Mozilla VPN (services with systemd-resolved)
- **Disk utilities**: baobab (disk usage analyzer), dysk

### Nix Features Enabled

- **Flakes**: `experimental-features = ["flakes"]` with flake.lock version pinning
- **Nix Command**: `experimental-features = ["nix-command"]`
- **nix-ld**: Enabled for running prebuilt Linux binaries
- **nh**: Nix helper enabled with flake path `/etc/nixos`

### Running Non-NixOS Binaries

The system has `nix-ld` configured with extensive libraries for running prebuilt binaries (see `/etc/nixos/modules/system/nix-ld.nix`):

**Core Libraries**: fuse2, stdenv.cc, zlib, openssl, glib, gtk3, nss, nspr, pulseaudio, dbus, alsa-lib

**Graphics & Display**: X11 (libX11, libXext, libXi, libXrender, libXrandr, libXtst, libXcursor, libXfixes, libXdamage, libXcomposite, libXinerama, libxkbfile, libxkbcommon), mesa, libdrm, libGL, libglvnd, vulkan-loader, wayland, cairo, pango, gdk-pixbuf, harfbuzz

**Qt6 Support** (for Android Emulator GUI): qt6.qtbase, qt6.qtwayland, qt6.qtsvg, qt6.qtdeclarative, qt6.qt5compat

**Accessibility & Fonts**: at-spi2-core, at-spi2-atk, fontconfig, freetype

**Other**: libxslt, libxml2, icu, xcb utilities (image, keysyms, renderutil, wm)

This comprehensive library set enables running Android Studio emulator, Qt applications, and most Linux binaries.

## System Services

### Active Services

- **Display**: X11 with Cinnamon desktop (unstable, no longer pinned to stable)
- **Audio**: PipeWire (replaces PulseAudio)
- **Networking**: NetworkManager (not wpa_supplicant)
- **Bluetooth**: Enabled and auto-start on boot
- **Printing**: CUPS enabled
- **Firmware Updates**: fwupd enabled
- **Thermal Management**: thermald for Intel CPU
- **SSD Optimization**: fstrim enabled
- **Flatpak**: Enabled for additional package management
- **Fingerprint Authentication**: fprintd enabled with PAM integration
- **VPN**: Mullvad VPN and Mozilla VPN services with systemd-resolved
- **DNS**: systemd-resolved (required for VPN services)

### Power Management

- using `power-profiles-daemon` (not TLP)
- nvidia power management disabled (for stability with hybrid graphics)

### Firewall

- **Status**: enabled by default (nixos firewall)
- **Steam ports**: automatically opened via steam module (remote play, dedicated server)
- **Configuration**: comment examples in configuration.nix for reference

## Special Program Configurations

Some programs require `programs.<name>.enable` instead of just adding to packages:

- **wireshark**: `programs.wireshark.enable = true` - adds packet capture capabilities without sudo (user in wireshark group)
- **obs-studio**: `programs.obs-studio` - enables virtual camera (v4l2loopback) and CUDA encoding
- **mullvad-vpn**: `services.mullvad-vpn` - runs as system service with systemd-resolved
- **mozilla-vpn**: `services.mozillavpn` - mozilla vpn service
- **adb**: provided by the `android-tools` package; `programs.adb` is intentionally disabled (systemd 258 uaccess udev rules grant USB device access automatically — no `adbusers` group needed)
- **steam**: `programs.steam` - handles firewall configuration automatically
- **gamemode**: `programs.gamemode.enable = true` - automatic performance optimizations when gaming (enabled)
- **nh**: `programs.nh` - nix helper for better flake rebuild experience

These are configured in `/etc/nixos/modules/system/programs.nix`, `/etc/nixos/modules/system/steam.nix`, and `/etc/nixos/modules/system/vpn.nix`.

## Common Tasks

### Adding a New Package

1. search for it: `nix search nixpkgs <name>`
2. add to the appropriate location:
   - **user packages**: `/etc/nixos/home.nix` in `home.packages`
   - **system packages**: `/etc/nixos/configuration.nix` in `environment.systemPackages`
3. rebuild: `ns` (using nh) or `sn` (traditional)

### Adding a Module

1. create a NixOS system module at `/etc/nixos/modules/system/newmodule.nix`
2. add `../../modules/system/newmodule.nix` to the imports list in `hosts/salad/configuration.nix` (the import path uses `../../` from `hosts/salad/`)
3. rebuild: `ns`

For home-manager modules: add a cross-platform module under `modules/home/common/`, or a platform-specific override under `modules/home/linux/` or `modules/home/darwin/`, then import it from the relevant entrypoint (`home/salad.nix` or `home/datadog.nix`).

### Updating System

```bash
nu              # update flake inputs + rebuild
nix flake update /etc/nixos && ns
```

### Troubleshooting Boot Issues

- systemd-boot is configured with 10 configuration rollback options
- at boot, select a previous generation if new config fails
- luks encrypted drives will auto-unlock via tpm2 (password as fallback)

### Checking System Info

```bash
nixos-version          # nixos version
nix --version          # nix package manager version
uname -r               # kernel version
lspci | grep -i vga    # graphics card info
```

## Important Notes

- **unfree packages allowed**: `nixpkgs.config.allowUnfree = true`
- **user**: salad (wheel, networkmanager, video, audio, kvm, docker, wireshark, gamemode groups)
- **default shell**: zsh with oh-my-zsh, starship prompt, syntax highlighting, and autosuggestions
- **timezone**: America/New_York
- **locale**: en_US.UTF-8
- **keyboard**: US layout
- **system state version**: 25.11 (do not change without reading docs)
- **nix settings**: flakes and nix-command enabled, trusted users include @wheel, auto-optimize-store enabled

## Boot Configuration

### TPM2 Auto-Unlock (Enabled)

The system uses TPM2 to automatically unlock LUKS encryption at boot:

- **boot flow**: plymouth splash → tpm2 auto-unlock → cinnamon login → desktop
- **security**: password still required as backup if tpm2 fails
- **configuration**: `boot.initrd.systemd.enable = true` enables tpm2 support

**re-enrolling tpm2 after hardware changes:**

```bash
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme1n1p2
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme1n1p3
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme1n1p2
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme1n1p3
```

**check current luks slots:**

```bash
sudo cryptsetup luksDump /dev/nvme1n1p2 | grep -E "(Keyslots:|^\s+[0-9]+:)"
```

### Security Considerations (TPM2 Auto-Unlock)

**Current threat model:**

| Threat | Protection |
|--------|------------|
| Laptop stolen while off | ✅ TPM2 bound to hardware, attacker can't boot on different machine |
| Evil maid (boot tampering) | ⚠️ PCR 0+7 should detect, but sophisticated attacks possible |
| Laptop stolen while suspended | ❌ RAM contains decryption keys |
| Cold boot attack | ❌ Vulnerable (RAM can be frozen and read) |

**The vulnerability:** With TPM2 auto-unlock, the login screen (fingerprint/password) is the *only* barrier after boot. The drive decrypts automatically if the hardware is unmodified. This is a convenience vs security tradeoff.

**Future hardening option - YubiKey FIDO2:**

To require physical presence (YubiKey tap) at boot instead of TPM2 auto-unlock:

```bash
# 1. Install yubikey support in NixOS config:
#    hardware.u2f.enable = true;
#    environment.systemPackages = [ pkgs.yubikey-manager ];

# 2. Verify YubiKey is detected
ykman info

# 3. Remove TPM2 auto-unlock (keeps password as backup)
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme1n1p2
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme1n1p3

# 4. Enroll YubiKey FIDO2
sudo systemd-cryptenroll /dev/nvme1n1p2 --fido2-device=auto --fido2-with-user-presence=true
sudo systemd-cryptenroll /dev/nvme1n1p3 --fido2-device=auto --fido2-with-user-presence=true

# Boot becomes: plug in YubiKey → tap → fingerprint login
# Backup: type password if YubiKey lost (slot 0 preserved)
```

**Recommendation:** Current setup is reasonable for most threat models. Consider YubiKey FIDO2 if traveling with sensitive data or working in high-security environments.

### Plymouth & Silent Boot (Enabled)

- kernel messages hidden for clean boot experience
- bootloader menu hidden (timeout=0)
- additional kernel params: `i915.enable_psr=0` (reduces intel flickering)

## Fingerprint Authentication

### Hardware

- **device**: synaptics fingerprint reader (06cb:00f9)
- **status**: **enabled** and fully configured

### Configuration

fingerprint authentication is **currently enabled** with the following pam integration:

- **login screen** (lightdm): fingerprint or password
- **sudo commands**: fingerprint or password
- **polkit-1** (system authorization): fingerprint or password
- **cinnamon screensaver**: fingerprint or password
- **general login pam**: fingerprint support enabled

### Power Management Integration

the system includes special handling to prevent fingerprint reader corruption:
- fprintd service is automatically stopped before system suspend
- this prevents potential data corruption when resuming from sleep
- configured via `powerManagement.powerDownCommands`

### USB Power Management

usb autosuspend is disabled for the fingerprint reader to ensure reliability:
- device won't enter power-saving mode during operation
- configured via udev rule matching vendor/product id (06cb:00f9)

### Managing Fingerprints

**enroll a fingerprint:**

```bash
fprintd-enroll
```

**list enrolled fingerprints:**

```bash
fprintd-list salad
```

**delete fingerprints:**

```bash
fprintd-delete salad
```

**verify device is detected:**

```bash
lsusb | grep synaptics
```

**to disable fingerprint authentication:**

edit `/etc/nixos/modules/system/fingerprint.nix` and comment out or rebuild without importing it.

## YubiKey

### Hardware

- **device**: YubiKey (FIDO2/U2F)
- **status**: **enabled** for web authentication
- **location**: `/etc/nixos/modules/system/yubikey.nix`

### Current Configuration

- `services.pcscd.enable = true` - smart card daemon for YubiKey communication
- `yubikey-manager` (ykman) - CLI tool for YubiKey management
- `yubioath-flutter` - GUI for YubiKey management (Yubico Authenticator)
- **OTP slots**: Both empty (prevents accidental character spam on touch)
- **FIDO PIN**: Set (protects FIDO2 credentials if YubiKey is stolen)

### Usage

**verify yubikey is detected:**

```bash
ykman info
```

**registering on websites:**

1. Go to site's security settings (GitHub, Google, AWS, Cloudflare, etc.)
2. Look for "Security Key", "Passkey", or "Hardware Key"
3. Follow prompts and tap YubiKey when it blinks

### FIDO2 vs TOTP

| Method | How it works | Security |
|--------|--------------|----------|
| FIDO2/U2F | Tap YubiKey when prompted | Phishing-proof (origin-bound) |
| TOTP (Aegis) | Type 6-digit code | Can be phished |

**Recommendation**: Use FIDO2 on sites that support it, keep Aegis for TOTP-only sites.

### Future Options

**FIDO2 SSH keys** (simpler than GPG):
```bash
# Generate resident SSH key on YubiKey
ssh-keygen -t ed25519-sk -O resident -O application=ssh:mykey
# Requires tap for each SSH connection
```

**GPG keys on YubiKey**: See gpg-ssh module - can move existing GPG keys to hardware for git signing and SSH.

**LUKS FIDO2**: See "Security Considerations (TPM2 Auto-Unlock)" section for replacing TPM2 with YubiKey tap at boot.

## Gaming

### Steam

- **status**: enabled with remote play and dedicated server firewall ports
- **location**: `/etc/nixos/modules/system/steam.nix`
- **proton-ge**: installed via `extraCompatPackages` for better compatibility and performance
- **input fix**: SDL environment variables configured to fix X11 click/input issues
  - `SDL_VIDEODRIVER=x11` - forces SDL2 to use X11 backend
  - `SDL_VIDEO_X11_DGAMOUSE=0` - disables legacy DGA mouse mode

**common issues:**
- **can't click in games**: fixed by SDL environment variables in steam.nix
- **using proton-ge**: right-click game → Properties → Compatibility → select "GE-Proton"

### Gamemode

- **status**: **enabled**
- **function**: automatically applies system optimizations when games start
- sets cpu governor to performance mode
- prioritizes game processes
- reverts changes when games close

**how to use:**
```bash
gamemoderun ./game    # manually launch with gamemode
```

steam automatically uses gamemode if enabled.

## Android & Mobile Development

### ADB (Android Debug Bridge)

adb is enabled system-wide for android device debugging and development:

```bash
# check connected devices
adb devices

# install an apk
adb install app.apk

# access device shell
adb shell

# logcat for debugging
adb logcat
```

**note**: adb works without root via the `android-tools` package + systemd 258 uaccess udev rules. `programs.adb` is disabled and there is no `adbusers` group (the udev rules tag the device for the logged-in seat instead).

### Android Studio

android studio is installed with full emulator support. the `nix-ld` configuration includes all necessary libraries for the android emulator gui:

- qt6 libraries for emulator interface
- vulkan and opengl support for hardware acceleration
- x11 and wayland support

### React Native Development

watchman is installed for react native file watching and hot reload functionality.

## Additional System Features

- **gtk themes**: multiple themes installed (gruvbox, arc, nordic, dracula, catppuccin, spacx, palenight, oceanic, gruvterial)
- **fonts**: roboto, iosevka nerd font, comic mono, aileron, atkinson hyperlegible, cantarell, adwaita
- **gpm**: mouse support in tty enabled
- **lightdm**: custom background from `/etc/nixos/assets/darkcarp.jpeg` (processed via imagemagick), hidpi enabled, mint-y-dark theme

## Shell Aliases

Configured in `/etc/nixos/modules/home/linux/zsh.nix`:

```bash
ns      # nh os switch path:/etc/nixos (rebuild only, no updates)
nu      # nh os switch path:/etc/nixos -u (update ALL inputs including kernel + rebuild)
ua      # update apps only (safe - skips kernel input to avoid NVIDIA breakage)
sn      # sudo nixos-rebuild switch (traditional fallback)
ll      # eza -lh --group-directories-first --icons --git
la      # eza -lah --group-directories-first --icons
ls      # eza --group-directories-first --icons
lt      # eza --tree --level=2 --group-directories-first --icons
cd      # z (zoxide)
```

**Recommended workflow:**
- `ns` - after editing config
- `ua` - regular updates (apps only, safe -- excludes kernel)
- `nu` - updates everything including kernel (check NVIDIA compat first)

## Optional/Disabled Features

some features are commented out in modules that can be enabled:

1. **ssh server**: uncomment in configuration.nix for inbound ssh access
2. **alternative desktop environments**: gnome or kde plasma 6 (commented in configuration.nix)
3. **podman**: in `/etc/nixos/modules/system/containers.nix` - alternative to docker

## Known Issues / Workarounds

### RedisInsight
- **Status**: Broken in nixpkgs (missing `nix-prefetch-git` in build sandbox)
- **Workaround**: Use Flatpak (`flatpak install flathub com.redis.RedisInsight`) or wait for upstream fix

### CachyOS Kernel + NVIDIA
- **Issue**: New kernel versions may not be supported by NVIDIA drivers yet
- **Symptom**: Build fails with errors like `too few arguments to function 'zone_device_page_init'`
- **Current status**: NVIDIA 595.x supports kernel 6.19 -- no current issues
- **If it breaks after `nu`**: Use `ua` for safe updates (excludes kernel), or pin the kernel with `?rev=` in `flake.nix`
- **Check compatibility**: `nix eval --raw 'github:xddxdd/nix-cachyos-kernel/release#packages.x86_64-linux.linux-cachyos-latest.version'`

### Cinnamon Backlight / Brightness Keys
- **Issue**: polkit 127 uses `realpath` when comparing `org.freedesktop.policykit.exec.path`, which breaks NixOS symlink paths. `csd-power` falls back from `gnome-rr` (xrandr Backlight property not available with `modesetting` driver) to `csd-backlight-helper` via `pkexec`, and polkit rejects the authorization because the resolved nix store path doesn't match the policy's symlink path.
- **Fix**: polkit rule in `configuration.nix` auto-authorizes `csd-backlight-helper` for `video` group users:
  ```nix
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.policykit.exec" &&
          action.lookup("program").indexOf("csd-backlight-helper") >= 0 &&
          subject.isInGroup("video")) {
        return polkit.Result.YES;
      }
    });
  '';
  ```
- **Root cause**: polkit 126→127 upgrade (via `nix flake update` on Feb 11, 2026)
- **Why modesetting**: required for NVIDIA hybrid graphics; the `intel` DDX driver exposes xrandr `Backlight` property but `modesetting` does not

### Cinnamon Crash on Window Open (grouped-window-list segfault)
- **Symptom**: Cinnamon crashes (SIGSEGV in `_clutter_actor_queue_only_relayout` → `clutter_actor_add_child_internal` → `st_bin_set_child`) when opening any window, especially Electron/Chromium apps
- **Root cause**: `grouped-window-list@cinnamon.org` applet calls `this.iconBox.set_child(icon)` synchronously during muffin's `window-created` signal (`_meta_window_shared_new`). The Clutter actor tree is not yet stable during this signal, and `clutter_actor_add_child_internal` triggers a relayout that dereferences a parent pointer in an inconsistent state, causing a segfault.
- **Fix**: Local patched copy at `~/.local/share/cinnamon/applets/grouped-window-list@cinnamon.org/appGroup.js`:
  1. Defers `set_child()` to a `GLib.idle_add()` callback so the actor tree is stable before reparenting
  2. Removes icon from existing parent before `set_child()` as an additional safety check
  3. Cleans up pending idle source in `destroy()` to prevent use-after-free
- **Affects**: Both Cinnamon 6.4.x and 6.6.x — upstream bug, not version-specific
- **Note**: This local copy overrides the system applet. After Cinnamon updates, check if the fix is still needed or if upstream patched it

## Resources

- nixos mcp: https://mcp-nixos.io/
- nixos manual: https://nixos.org/manual/nixos/stable/
- nixos wiki: https://wiki.nixos.org/
- package search: https://search.nixos.org/packages
- nixos options: https://search.nixos.org/options
- verifying config changes: `nd` alias / `nix store diff-closures` (see "Verifying Configuration Changes")
- nix flakes: https://nixos.wiki/wiki/Flakes
- cachyos kernel commits: https://github.com/xddxdd/nix-cachyos-kernel/commits/release

## NEXT

you may also read docs/CONTEXT.md (supporting docs live in docs/: CONTEXT.md, wifi.md, AUDIT.md)
