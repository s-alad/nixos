{ pkgs, lib, ... }:

# cinnamon applets: 5 third-party from the spices monorepo (pinned), plus
# grouped-window-list rebuilt from the current cinnamon + segfault patch
# (see CLAUDE.md). to bump: update rev, hash = lib.fakeHash, rebuild, paste hash.
let
  thirdParty = [
    "classic-menu@fredcw"
    "CassiaWindowList@klangman"
    "cpu-monitor-text@gnemonix"
    "nvidiaprime@pdcurtis"
    "weather@mockturtl"
  ];

  spicesSrc = pkgs.fetchFromGitHub {
    owner = "linuxmint";
    repo = "cinnamon-spices-applets";
    rev = "2af76d24ced03233ac4a9b68d65d0dfe705ca93a";
    sparseCheckout = thirdParty;
    hash = "sha256-FqTrntAPioiiGJzKS5cbaF0jDO8NGNprMQR+RZpqSRY=";
  };

  grouped-window-list = pkgs.runCommand "grouped-window-list-patched" {
    nativeBuildInputs = [ pkgs.patch ];
  } ''
    cp -r ${pkgs.cinnamon-common}/share/cinnamon/applets/grouped-window-list@cinnamon.org $out
    chmod -R u+w $out
    patch $out/appGroup.js < ${../../../assets/grouped-window-list-segfault.patch}
  '';
in
{
  xdg.dataFile = lib.listToAttrs (map (uuid: {
    name = "cinnamon/applets/${uuid}";
    value.source = "${spicesSrc}/${uuid}/files/${uuid}";
  }) thirdParty) // {
    "cinnamon/applets/grouped-window-list@cinnamon.org".source = grouped-window-list;
  };
}
