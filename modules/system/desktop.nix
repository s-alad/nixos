{ pkgs, ... }:

let
  bg = import ../../lib/lightdm-background.nix { inherit pkgs; };
in
{
  # --- Cinnamon desktop + LightDM (slick greeter)
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

  # --- alternative desktops (disabled)
  ### GNOME
  # services.xserver.displayManager.gdm.enable = true;
  # services.xserver.desktopManager.gnome.enable = true;
  ### KDE
  # services.displayManager.sddm.enable = true;
  # services.displayManager.sddm.wayland.enable = true;
  # services.desktopManager.plasma6.enable = true;
}
