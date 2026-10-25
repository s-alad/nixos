{ ... }:

# nixbuild.net remote builder. Active: anything that can't be downloaded from a
# binary cache (mainly the CachyOS kernel on `nu`) is compiled there.
# Kept intact intentionally — do not remove.
{
  nix.distributedBuilds = true;
  # let nixbuild.net fetch build inputs from cache.nixos.org itself instead of
  # uploading them from this machine
  nix.settings.builders-use-substitutes = true;
  nix.buildMachines = [
    {
      hostName = "eu.nixbuild.net";
      system = "x86_64-linux";
      maxJobs = 100;
      supportedFeatures = [ "benchmark" "big-parallel" ];
    }
  ];

  programs.ssh.extraConfig = ''
    Host eu.nixbuild.net
    PubkeyAcceptedKeyTypes ssh-ed25519
    ServerAliveInterval 60
    IPQoS throughput
    IdentityFile /home/salad/.ssh/id_ed25519
    # keep remote builds running if this machine disconnects (shutdown/Ctrl+C);
    # re-running the rebuild picks up the finished result
    SetEnv NIXBUILDNET_KEEP_BUILDS_RUNNING=true
  '';

  programs.ssh.knownHosts = {
    nixbuild = {
      hostNames = [ "eu.nixbuild.net" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIQCZc54poJ8vqawd8TraNryQeJnvH1eLpIDgbiqymM";
    };
  };
}
