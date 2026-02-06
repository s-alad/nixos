{ config, pkgs, lib, ... }:

{
  # --- GPG agent with SSH support
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
}
