{ config, pkgs, lib, ... }:

{
  # --- firefox
  programs.firefox.enable = true;

  # --- java
  programs.java = {
    enable = true;
    package = pkgs.jdk;
  };

  # --- android debug bridge
  programs.adb.enable = true;

  # --- wireshark with packet capture capabilities
  programs.wireshark.enable = true;

  # --- obs-studio with virtual camera and nvidia cuda encoding
  programs.obs-studio = {
    enable = true;
    enableVirtualCamera = true;
    package = pkgs.obs-studio.override { cudaSupport = true; };
  };

  # --- nh
  # programs.nh = {
  #   enable = true;
  #   clean.enable = true;
  # };
}
