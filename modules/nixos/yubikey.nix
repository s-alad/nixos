{ config, pkgs, lib, ... }:

{
  # --- Smart card daemon (required for YubiKey communication)
  services.pcscd.enable = true;

  # --- YubiKey management tools
  # Note: FIDO2/U2F udev rules are now built into udev natively (no hardware.u2f needed)
  environment.systemPackages = with pkgs; [
    yubikey-manager   # ykman CLI for configuration and status
    yubioath-flutter  # GUI for YubiKey management (Yubico Authenticator)
  ];
}
