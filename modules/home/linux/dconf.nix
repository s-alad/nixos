# cinnamon + nemo settings - dconf dump | dconf2nix, only deviations from schema defaults
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/cinnamon" = {
      # alt-tab shows icons only, no window thumbnails
      alttab-switcher-style = "icons";
      # disable window open/close animations
      desktop-effects = false;
      # panel layout: every applet as panel:zone:position:uuid:id
      enabled-applets = [ "panel1:left:1:separator@cinnamon.org:1" "panel1:right:14:systray@cinnamon.org:3" "panel1:right:15:xapp-status@cinnamon.org:4" "panel1:right:16:notifications@cinnamon.org:5" "panel1:right:17:printers@cinnamon.org:6" "panel1:right:19:keyboard@cinnamon.org:8" "panel1:right:20:favorites@cinnamon.org:9" "panel1:right:21:network@cinnamon.org:10" "panel1:right:22:sound@cinnamon.org:11" "panel1:right:23:power@cinnamon.org:12" "panel1:right:25:calendar@cinnamon.org:13" "panel1:right:26:cornerbar@cinnamon.org:14" "panel1:right:24:settings@cinnamon.org:15" "panel1:left:0:classic-menu@fredcw:18" "panel1:left:2:grouped-window-list@cinnamon.org:26" "panel1:right:1:windows-quick-list@cinnamon.org:27" "panel1:right:0:workspace-switcher@cinnamon.org:28" ];
      # entries in the favorites applet
      favorite-apps = [ "firefox.desktop" "org.gnome.Software.desktop" "cinnamon-settings.desktop" "org.gnome.Terminal.desktop" "nemo.desktop" ];
      # app icon size per panel zone
      panel-zone-icon-sizes = "[{\"panelId\": 1, \"left\": 0, \"center\": 0, \"right\": 16}]";
      # symbolic (tray/status) icon size per panel zone
      panel-zone-symbolic-icon-sizes = "[{\"panelId\": 1, \"left\": 22, \"center\": 20, \"right\": 16}]";
      # text size per panel zone
      panel-zone-text-sizes = "[{\"panelId\": 1, \"left\": 9.0, \"center\": 0.0, \"right\": 0.0}]";
      # panel intellihide
      panels-autohide = [ "1:intel" ];
      # panel height 30px
      panels-height = [ "1:30" ];
    };

    "org/cinnamon/desktop/background" = {
      # wallpaper scaling mode
      picture-options = "centered";
      # wallpaper (file deployed by home/salad.nix)
      picture-uri = "file:///home/salad/Pictures/darkcarp.jpeg";
    };

    "org/cinnamon/desktop/background/slideshow" = {
      # folder the wallpaper picker browses
      image-source = "directory:///home/salad/Pictures";
    };

    "org/cinnamon/desktop/input-sources" = {
      # keyboard layout
      sources = [ (mkTuple [ "xkb" "us" ]) ];
    };

    "org/cinnamon/desktop/interface" = {
      # gtk app theme
      gtk-theme = "Mint-Y-Dark";
      # icon set
      icon-theme = "Mint-Y";
    };

    "org/cinnamon/desktop/peripherals/touchpad" = {
      # keep touchpad active while typing
      disable-while-typing = false;
      # pointer speed slider
      speed = 0.3697478991596639;
    };

    "org/cinnamon/desktop/wm/preferences" = {
      # two workspaces
      num-workspaces = 2;
      # workspace names
      workspace-names = [ "main" "server" ];
    };

    "org/cinnamon/muffin" = {
      # wrap around when cycling workspaces
      workspace-cycle = true;
    };

    "org/cinnamon/settings-daemon/plugins/power" = {
      # force pkexec backlight helper (pairs with the polkit rule in configuration.nix)
      backlight-helper-force = true;
      # never blank the display on AC
      sleep-display-ac = 0;
      # never blank the display on battery
      sleep-display-battery = 0;
    };

    "org/cinnamon/sounds" = {
      # no workspace-switch sound
      switch-enabled = false;
    };

    "org/cinnamon/theme" = {
      # cinnamon shell theme (panel/menus)
      name = "Mint-Y-Dark";
    };

    "org/nemo/desktop" = {
      # no icons on the desktop
      desktop-layout = "false::false";
    };

    "org/nemo/list-view" = {
      # column order in list view
      default-column-order = [ "name" "size" "type" "date_modified" "date_created_with_time" "date_accessed" "date_created" "detailed_type" "group" "where" "mime_type" "date_modified_with_time" "octal_permissions" "owner" "permissions" ];
      # columns shown by default
      default-visible-columns = [ "name" "size" "type" "date_modified" "date_created" ];
    };

    "org/nemo/preferences" = {
      # list view by default
      default-folder-viewer = "list-view";
      # show dotfiles
      show-hidden-files = true;
      # extra toolbar buttons
      show-computer-icon-toolbar = true;
      show-home-icon-toolbar = true;
      show-new-folder-icon-toolbar = true;
      show-open-in-terminal-toolbar = true;
      show-reload-icon-toolbar = true;
      show-show-thumbnails-toolbar = true;
    };

    "org/nemo/preferences/menu-config" = {
      # right-click menu: show "duplicate"
      selection-menu-duplicate = true;
    };

    "org/nemo/search" = {
      # search results newest first
      search-reverse-sort = true;
      # sort search results by modified date
      search-sort-column = "date_modified";
    };
  };
}
