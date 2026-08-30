{ config, pkgs, ... }:

# Hybrid Intel/NVIDIA graphics — PRIME offload mode, ThinkPad P1 Gen 8.
{
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

  # --- NVIDIA + intel hybrid graphics video drivers
  services.xserver.videoDrivers = [ "modesetting" "nvidia" ];

  # --- use Intel iHD for VA-API video acceleration
  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "iHD";
  };
}
