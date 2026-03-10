{ config, pkgs, lib, ... }:

{
  # --- GPG agent with SSH support
  programs.gnupg.agent = {
    # - auto fetches pkgs; [gnupg]
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
}
