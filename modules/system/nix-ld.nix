{ config, pkgs, lib, ... }:

{
  # --- enable nix-ld for running prebuilt Linux binaries
  programs.nix-ld.enable = true;

  programs.nix-ld.libraries = with pkgs; [
    # - core libraries
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

    # - X11 and graphics
    libx11
    libxcb
    libxext
    libxi
    libxrender
    libxrandr
    libxtst
    libxcursor
    libxfixes
    libxdamage
    libxcomposite
    libxinerama
    libxkbfile
    libsm
    libice
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-wm
    mesa
    libdrm
    libGL
    libglvnd
    vulkan-loader

    # - wayland
    wayland

    # - audio and input
    dbus
    alsa-lib
    libxkbcommon

    # - Qt6 libraries (for Android Emulator GUI)
    qt6.qtbase
    qt6.qtwayland
    qt6.qtsvg
    qt6.qtdeclarative
    qt6.qt5compat

    # - fonts and rendering
    fontconfig
    freetype
    cairo
    pango
    gdk-pixbuf
    harfbuzz

    # - accessibility
    at-spi2-core
    at-spi2-atk

    # - XML/data processing
    libxslt
    libxml2
    icu

    # - misc (Android emulator)
    libbsd
  ];
}
