{ pkgs, ... }:

{
  # --- bootloader (systemd-boot, 10-generation rollback)
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
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
  # --- wifi crash management (boot-time iwlwifi tuning; runtime offload fix is in wifi-offload-fix.nix)
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=0 swcrypto=1 11n_disable=8 disable_11be=1
  '';
}
