{ config, pkgs, lib, ... }:


let
  bg = import ../../lib/lightdm-background.nix { inherit pkgs; };
  devenv-init = pkgs.writeShellScriptBin "devenv-init" (builtins.readFile ../../scripts/devenv-init.sh);
in
{
  imports =
    [
      ./hardware-configuration.nix
      ../../modules/system/locale.nix
      ../../modules/system/fonts.nix
      ../../modules/system/fingerprint.nix
      ../../modules/system/containers.nix
      ../../modules/system/zsh.nix

      ../../modules/system/gpg-ssh.nix
      ../../modules/system/nix-ld.nix
      ../../modules/system/steam.nix
      ../../modules/system/vpn.nix
      ../../modules/system/programs.nix
      ../../modules/system/yubikey.nix
      ../../modules/system/appimage.nix
      ../../modules/system/tailscale.nix
      ../../modules/system/wifi-offload-fix.nix
    ];


  ##### BOOTLOADER
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  #boot.kernelPackages = pkgs.linuxPackages;  # stable 6.12 LTS (was linuxPackages_latest 6.18.2)
  #boot.kernelPackages = pkgs.linuxPackages_latest; # latest stable 6.18.2
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest; # CachyOS with EEVDF scheduler
  # --- explicit kernel modules
  boot.kernelModules = [ "kvm-intel" ];
  # --- silent boot
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    # - intel reduce flickering
    "i915.enable_psr=0"
    # - clean boot
    "quiet"
    "splash"
    "intremap=on"
    "boot.shell_on_fail"
    "udev.log_priority=3"
    "rd.systemd.show_status=auto"
  ];
  # --- systemd initrd for TPM2 auto-unlock
  boot.initrd.systemd.enable = true;
  # --- LUKS devices (TPM2 enrolled)
  # - $ sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme1n1p2
  # - $ sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme1n1p3
  boot.initrd.luks.devices = {
    "luks-d96ca84d-a4ef-4faf-944d-892d3bf7e910" = {
      device = "/dev/disk/by-uuid/d96ca84d-a4ef-4faf-944d-892d3bf7e910";
    };
    "luks-fcd35927-da32-4090-9abc-51eb75a4a6d5" = {
      device = "/dev/disk/by-uuid/fcd35927-da32-4090-9abc-51eb75a4a6d5";
    };
  };
  # --- plymouth startup animation
  boot.plymouth.enable = true;
  # --- hide the OS choice for bootloaders unless any key pressed
  boot.loader.timeout = 0;
  # --- wifi crash management
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0 swcrypto=1 11n_disable=8 disable_11be=1
  '';
  #####


  ##### NETWORKING 
  # --- hostname
  networking.hostName = "salad";
  # --- enable networking
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.powersave = false;
  # --- captive portal detection (airline wifi, hotel wifi, etc.)
  networking.networkmanager.settings.connectivity = {
    uri = "http://nmcheck.gnome.org/check_network_status.txt";
    interval = 300;
  };
  # --- firewall
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # networking.firewall.enable = false;
  #####


  ##### HARDWARE
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [ 
      intel-media-driver # video acceleration
      # intel-compute-runtime # opencl
    ];
  };
  hardware.nvidia = {
    open = true;
    modesetting.enable = true;   # tear-free rendering on X11
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
      # Optimus PRIME Option A: Offload Mode
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      # Optimus PRIME Option B: Sync Mode
      # sync.enable = true;        # smoother performance ; less battery

      # BUS ID
      intelBusId = "PCI:0:2:0";  # from lspci: 00:02.0
      nvidiaBusId = "PCI:1:0:0"; # from lspci: 01:00.0
    };

    powerManagement.enable = false;
    powerManagement.finegrained = false;
  };
  hardware.sensor.iio.enable = true;
  hardware.cpu.intel.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;
  # --- explicit bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  #####


  ##### ENV
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
  #####


  ##### SERVICES
  ### CINNAMON
  environment.etc."lightdm-background.jpg".source = bg;
  services.xserver.desktopManager.cinnamon.enable = true;
  services.xserver.displayManager.lightdm = {
    enable = true;
    
    greeters.slick = {
      enable = true;
      theme = {
        name = "Mint-Y-Dark";
      };
      iconTheme = {
        name = "Mint-Y";
      };
      extraConfig = ''
        enable-hidpi = on
        background = /etc/lightdm-background.jpg
        background-mode = center
      '';
    };
  };
  ### GNOME
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  ### KDE
  # services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = true;
  # services.desktopManager.plasma6.enable = true;
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
  # Allow `sst tunnel` (SST CLI's VPC tunnel helper) to start its
  # privileged worker without prompting for sudo. Installed by
  # `sudo npx sst tunnel install` into /opt/sst/tunnel.
  security.sudo.extraRules = [
    {
      users = [ "salad" ];
      commands = [
        {
          command = "/opt/sst/tunnel tunnel start *";
          options = [ "NOPASSWD" "SETENV" ];
        }
      ];
    }
  ];
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
  # --- NVIDIA + intel hybrid graphics ; ThinkPad P1 Gen 8
  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];
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
    gruvbox-gtk-theme
    arc-theme
    nordic
    dracula-theme
    catppuccin-gtk
    spacx-gtk-theme
    palenight-theme
    oceanic-theme
    gruvterial-theme
    android-tools  # adb - systemd 258 handles uaccess rules automatically
    glow
    nvitop
    direnv
    devenv
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
    distributedBuilds = false;
    buildMachines = [
      {
        hostName = "eu.nixbuild.net";
        system = "x86_64-linux";
        maxJobs = 100;
        supportedFeatures = [ "benchmark" "big-parallel" ];
      }
    ];
  };

  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
    PubkeyAcceptedKeyTypes ssh-ed25519
    ServerAliveInterval 60
    IPQoS throughput
    IdentityFile /home/salad/.ssh/id_ed25519
  '';

  programs.ssh.knownHosts = {
    nixbuild = {
      hostNames = [ "eu.nixbuild.net" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };


  ##### SYSTEM
  # system.userActivationScripts.zshrc = "touch .zshrc";
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
