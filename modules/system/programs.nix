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
    # Keep 10 generations (matches systemd-boot configurationLimit) AND anything
    # younger than 30 days, so a rebuild burst can't push last-known-good past the count.
    # Without --keep, `nh clean` defaults to --keep 1 = zero rollback targets.
    clean.extraArgs = "--keep 10 --keep-since 30d";
    flake = "/etc/nixos";
  };
}
