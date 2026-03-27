# Vanta Device Monitor for compliance checks
# To remove: delete the import from configuration.nix, run `ns`, then:
#   sudo rm -rf /var/vanta
{ pkgs, ... }:

let
  vanta-files = pkgs.stdenv.mkDerivation {
    name = "vanta-files-2.16.1";
    src = pkgs.fetchurl {
      url = "https://app.vanta.com/osquery/download/linux";
      sha256 = "1wgpdhnnv72ims4hl85f2sv20plxlqb5glvz2g3wfgdn56wwr3mv";
      name = "vanta-amd64.deb";
    };
    nativeBuildInputs = [ pkgs.dpkg pkgs.autoPatchelfHook ];
    buildInputs = [ pkgs.glibc ];
    sourceRoot = ".";
    unpackCmd = "dpkg-deb -x $curSrc .";
    installPhase = ''
      mkdir -p $out/var/vanta
      cp -r var/vanta/* $out/var/vanta/
    '';
  };
in
{
  # --- Vanta config (key + owner email)
  environment.etc."vanta.conf" = {
    text = builtins.toJSON {
      ACTIVATION_REQUESTED_NONCE = 1;
      AGENT_KEY = "w7rdut9x7qwxe6q5bv80ndxm896f54x2hh4n751azkyey513c190";
      OWNER_EMAIL = "saad@paywithlocus.com";
      REGION = "us";
      NEEDS_OWNER = true;
    };
    mode = "0600";
  };

  # --- ensure /var/vanta directory exists
  systemd.tmpfiles.rules = [
    "d /var/vanta 0755 root root -"
  ];

  # --- Vanta systemd service
  systemd.services.vanta = {
    description = "Vanta monitoring software";
    after = [ "network.target" "syslog.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "/var/vanta/metalauncher";
      Restart = "on-failure";
      KillMode = "control-group";
      KillSignal = "SIGTERM";
      TimeoutStartSec = 0;
    };
    # copy patched binaries from Nix store to /var/vanta (metalauncher hardcodes this path)
    preStart = ''
      cp -f ${vanta-files}/var/vanta/* /var/vanta/
      chmod 755 /var/vanta/metalauncher /var/vanta/launcher /var/vanta/vanta-cli /var/vanta/osqueryd /var/vanta/osquery-vanta.ext
      chmod 644 /var/vanta/cert.pem
    '';
  };
}
