{ config, pkgs, lib, ... }:

{
  # --- enable nix-ld for running prebuilt Linux binaries
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    # --- core libraries
    fuse2
    stdenv.cc.cc
    zlib
    openssl
    glib
    gtk3
    nss
    nspr
    pulseaudio
    libpng
    expat

    # --- X11 and graphics
    xorg.libX11
    xorg.libxcb
    xorg.libXext
    xorg.libXi
    xorg.libXrender
    xorg.libXrandr
    xorg.libXtst
    xorg.libXcursor
    xorg.libXfixes
    xorg.libXdamage
    xorg.libXcomposite
    xorg.libXinerama
    xorg.libxkbfile
    xorg.libSM
    xorg.libICE
    xorg.xcbutilimage
    xorg.xcbutilkeysyms
    xorg.xcbutilrenderutil
    xorg.xcbutilwm
    mesa
    libdrm
    libGL
    libglvnd
    vulkan-loader

    # --- wayland
    wayland

    # --- audio and input
    dbus
    alsa-lib
    libxkbcommon

    # --- Qt6 libraries (for Android Emulator GUI)
    qt6.qtbase
    qt6.qtwayland
    qt6.qtsvg
    qt6.qtdeclarative
    qt6.qt5compat

    # --- fonts and rendering
    fontconfig
    freetype
    cairo
    pango
    gdk-pixbuf
    harfbuzz

    # --- accessibility
    at-spi2-core
    at-spi2-atk

    # --- XML/data processing
    libxslt
    libxml2
    icu
  ];
}
