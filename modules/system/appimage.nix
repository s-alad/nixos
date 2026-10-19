{ config, pkgs, lib, ... }:

let
  paper-src = pkgs.fetchurl {
    url = "https://download.todesktop.com/2601167vjw8xe/paper-desktop-0.5.16-build-261015tx3mukqib-x86_64.AppImage";
    hash = "sha256-GlCugWbyhzdNOaQodkWr5vXsPDEJ1ie4DWXMyWYDCm4=";
  };

  paper = pkgs.appimageTools.wrapType2 {
    pname = "paper";
    version = "0.5.16";
    src = paper-src;
    extraInstallCommands =
      let contents = pkgs.appimageTools.extract {
        pname = "paper";
        version = "0.5.16";
        src = paper-src;
      };
      in ''
        install -m 444 -D ${contents}/paper-desktop.desktop $out/share/applications/paper.desktop
        substituteInPlace $out/share/applications/paper.desktop \
          --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=paper %U'
        cp -r ${contents}/usr/share/icons $out/share
      '';
  };

  onekey-src = pkgs.fetchurl {
    url = "https://github.com/OneKeyHQ/app-monorepo/releases/download/v5.18.0/OneKey-Wallet-5.18.0-linux-x86_64.AppImage";
    hash = "sha256-WD2l7y11BAG4ik0gTz78AP/U+SfRUDbulv1+gtNGohQ=";
  };

  onekey = pkgs.appimageTools.wrapType2 {
    pname = "onekey";
    version = "5.18.0";
    src = onekey-src;
    extraInstallCommands =
      let contents = pkgs.appimageTools.extract {
        pname = "onekey";
        version = "5.18.0";
        src = onekey-src;
      };
      in ''
        install -m 444 -D ${contents}/onekey-wallet.desktop $out/share/applications/onekey.desktop
        substituteInPlace $out/share/applications/onekey.desktop \
          --replace-fail 'Exec=AppRun --no-sandbox %U' 'Exec=onekey %U'
        cp -r ${contents}/usr/share/icons $out/share
      '';
  };

in
{
  # --- binfmt: lets any AppImage run directly (chmod +x && ./app.AppImage)
  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  # --- wrapped AppImage derivations (desktop entries, icons, nix-managed)
  environment.systemPackages = [
    paper
    onekey
  ];
}
