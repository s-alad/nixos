{ ... }:

let
  secrets = import ../../../secrets.nix;
in
{
  # NixOS-specific git overrides (base config in modules/home/common/git.nix)

  # format = "ssh" makes HM emit both gpg.format and a pinned gpg.ssh.program,
  # rather than relying on ssh-keygen being on PATH.
  programs.git.signing = {
    format = "ssh";
    key = secrets.gitSigningKey;
    signByDefault = true;
  };

  programs.git.settings.safe.directory = "/etc/nixos";
}
