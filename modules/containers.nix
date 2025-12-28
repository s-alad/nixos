{ config, pkgs, lib, ... }:

{
  # docker containerization
  virtualisation.docker = {
    enable = true;
  };

  # podman alternative
  # virtualisation.podman = {
  #   enable = true;
  #   dockerCompat = true;  # Docker compatibility
  # };
}
