{ config, pkgs, lib, ... }:


let
  bg = import ./lib/lightdm-background.nix { inherit pkgs; };
  nixai = (builtins.getFlake "github:olafkfreund/nix-ai-help").packages.${pkgs.system}.default;
in
{
  imports =
    [
      ./hardware-configuration.nix
      ./modules/locale.nix
      ./modules/fonts.nix
      ./modules/fingerprint.nix
      ./modules/containers.nix
      ./modules/zsh.nix
      ./modules/starship.nix
      ./modules/gpg-ssh.nix
      ./modules/nix-ld.nix
      ./modules/steam.nix
      ./modules/vpn.nix
      ./modules/programs.nix
    ];


  ##### BOOTLOADER
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
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
    options iwlwifi power_save=0 swcrypto=1 11n_disable=8
  '';
  #####


  ##### NETWORKING 
  # --- hostname
  networking.hostName = "salad";
  # --- enable networking
  networking.networkmanager.enable = true;
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
  environment.interactiveShellInit = ''
    export GOPATH="$HOME/.local/share/go"
    export PATH="$PATH:$GOPATH/bin"
  '';
  #####


  ##### SERVICES
  ### CINNAMON
  environment.etc."lightdm-background.jpg".source = bg;
  services.xserver.desktopManager.cinnamon.enable = true;
  services.gnome.gnome-keyring.enable = true;
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
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  # --- flatpak
  services.flatpak.enable = true;
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
  # --- touchpad support (enabled default in most desktopManager)
  # services.xserver.libinput.enable = true;
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
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "kvm" "docker" "adbusers" "wireshark" ];
    packages = with pkgs; [
      thunderbird
      bottles
      discord
      slack
      claude-code
      code-cursor
      brave
      qbittorrent
      burpsuite
      zoom-us
      mongodb-compass
      obsidian
      postman
      redisinsight
      google-chrome
      element-desktop
      gimp2
      google-cloud-sdk
      awscli2
      gitfetch
      libreoffice
      prismlauncher
      cbonsai
      cowsay
      cmatrix
      sl
      oneko
      lolcat
      unityhub
      android-studio
      watchman
    ];
  };


  ##### PACKAGES
  environment.systemPackages = with pkgs; [
    vim
    wget
    efibootmgr
    pciutils
    usbutils
    btop-cuda
    htop
    git
    mesa-demos
    vulkan-tools
    nvtopPackages.full
    vscode
    nh
    helix
    libva-utils
    gnome-software
    signal-desktop
    fuse2
    neofetch
    file
    nodejs
    yarn
    go
    vlc
    ocaml
    redis
    chromium
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer
    gh
    starship
    ripgrep
    jdk
    jq
    uv
    lm_sensors
    gnumake
    gcc
    pkg-config
    eza
    zoxide
    fzf
    flameshot
    syncthing
    bat
    tmux
    ffmpeg
    gruvbox-gtk-theme
    arc-theme
    nordic
    dracula-theme
    catppuccin-gtk
    spacx-gtk-theme
    palenight-theme
    oceanic-theme
    gruvterial-theme
  ];


  ##### NIXPKGS
  # --- allow unfree packages
  nixpkgs.config.allowUnfree = true;


  ##### SETTINGS
  nix = {
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
  # system.userActivationScripts.zshrc = "touch .zshrc";
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?
}
