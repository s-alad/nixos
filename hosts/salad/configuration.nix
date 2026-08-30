{ config, pkgs, ... }:


let
  devenv-init = import ../../lib/devenv-init.nix { inherit pkgs; };
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/system/locale.nix
      ../../modules/system/boot.nix
      ../../modules/system/networking.nix
      ../../modules/system/graphics.nix
      ../../modules/system/desktop.nix
      ../../modules/system/fonts.nix
      ../../modules/system/fingerprint.nix
      ../../modules/system/containers.nix
      ../../modules/system/clamav.nix
      ../../modules/system/zsh.nix

      ../../modules/system/gpg-ssh.nix
      ../../modules/system/nix-ld.nix
      ../../modules/system/steam.nix
      ../../modules/system/vpn.nix
      ../../modules/system/programs.nix
      ../../modules/system/yubikey.nix
      ../../modules/system/appimage.nix
      ../../modules/system/tailscale.nix
      ../../modules/system/minecraft.nix
      ../../modules/system/wifi-offload-fix.nix
      ../../modules/system/sst.nix
      ../../modules/system/nixbuild.nix
    ];


  ##### HARDWARE (graphics lives in modules/system/graphics.nix)
  hardware.sensor.iio.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  # --- explicit bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  #####


  ##### SERVICES
  ### SOUND with pipewire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  # --- backlight control: auto-authorize csd-backlight-helper via pkexec
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.policykit.exec" &&
          action.lookup("program").indexOf("csd-backlight-helper") >= 0 &&
          subject.isInGroup("video")) {
        return polkit.Result.YES;
      }
    });
  '';
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  # --- flatpak
  services.flatpak.enable = false;
  # ---
  services.power-profiles-daemon.enable = true;
  # --- system wide power management
  powerManagement.enable = true;
  # --- X11 windowing system
  services.xserver.enable = true;
  # --- firmware updates
  services.fwupd.enable = true;
  # --- intel thermal management
  # NOTE: thermald 2.5.x doesn't yet support Arrow Lake (Core Ultra 9 285H) — for now it
  # logs "Unsupported cpu model or platform" and exits cleanly as a no-op (kernel HWP +
  # firmware DPTF handle thermals). Kept enabled so it auto-activates once a thermald build
  # adds 285H support; harmless until then.
  services.thermald.enable = true;
  # ---
  services.fstrim.enable = true;
  # --- keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };
  # --- enable CUPS to print documents
  services.printing.enable = true;
  # --- touchpad support
  services.libinput = {
    enable = true;
    touchpad.disableWhileTyping = false;
  };
  # --- OpenSSH daemon ; inbound
  # services.openssh.enable = true;
  # --- mouse support in tty
  services.gpm.enable = true;

  ### XDG
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
  };


  ##### USERS
  users.users.salad = {
    isNormalUser = true;
    shell = pkgs.zsh;
    description = "salad";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "kvm" "docker" "wireshark" "gamemode" ];
    # packages moved to home-manager (home.nix)
  };


  ##### PACKAGES
  environment.systemPackages = (import ../../packages/system-packages.nix { inherit pkgs; }) ++ (with pkgs; [
    efibootmgr
    pciutils
    usbutils
    btop-cuda
    htop
    glances
    duf
    tailspin
    mesa-demos
    vulkan-tools
    nvtopPackages.full
    vscode
    helix
    libva-utils
    gnome-software
    signal-desktop
    fuse2
    chafa
    file
    vlc
    ocaml
    redis
    chromium
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    gopls
    jdk
    uv
    lm_sensors
    smartmontools
    pkg-config
    flameshot
    syncthing
    seahorse
    tmux
    ffmpeg
    dysk
    baobab
    w3m
    unzip
    p7zip
    # gruvbox-gtk-theme, arc-theme, nordic, dracula-theme removed from nixpkgs
    # 2026-07-22 (depended on GTK 2 gtk-engine-murrine, unmaintained upstream)
    catppuccin-gtk
    spacx-gtk-theme
    palenight-theme
    oceanic-theme
    gruvterial-theme
    android-tools  # adb - systemd 258 handles uaccess rules automatically
    glow
    nvitop
    devenv-init
    codex
    traceroute
  ]);


  ##### NIXPKGS
  # --- allow unfree packages
  nixpkgs.config.allowUnfree = true;


  ##### SETTINGS
  nix = {
    # pure-flake system: disable legacy nix-channels.
    # (nix.nixPath still pins nixpkgs=flake:nixpkgs, so <nixpkgs> / nix-shell -p keep working.)
    channel.enable = false;

    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      trusted-users = [ "@wheel" ];
      auto-optimise-store = true;
    };
  };


  ##### SYSTEM
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
