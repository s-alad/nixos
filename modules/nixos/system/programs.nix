{ config, pkgs, lib, ... }:

{
  # --- firefox
  programs.firefox.enable = true;

  # --- java
  programs.java = {
    enable = true;
    package = pkgs.jdk;
  };

  # --- android debug bridge (android-tools added to system packages)
  # programs.adb is no longer needed - systemd 258 handles uaccess rules automatically

  # --- wireshark with packet capture capabilities
  programs.wireshark.enable = true;

  # --- obs-studio with virtual camera and nvidia cuda encoding
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    package = pkgs.obs-studio.override { cudaSupport = true; };
  };

  # --- nh (nix helper for flakes)
  programs.nh = {
    enable = true;
    clean.enable = true;
    # Keep 10 generations to match boot.loader.systemd-boot.configurationLimit = 10.
    # Without this, `nh clean` defaults to --keep 1 and the weekly run prunes every
    # rollback target, leaving a single generation (no boot-menu fallback after a bad rebuild).
    clean.extraArgs = "--keep 10";
    flake = "/etc/nixos";
  };
}
