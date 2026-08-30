{ pkgs, ... }:

{
  # --- ClamAV anti-malware
  #
  # Present for SOC2 / Vanta compliance (endpoint anti-malware control).
  #
  # NOTE: Vanta's Linux Device Monitor CANNOT auto-detect antivirus on Linux
  # (and doesn't support NixOS at all -- only specific Debian variants), so this
  # control is satisfied by MANUAL EVIDENCE, not by the agent phoning home:
  #   - `systemctl status clamav-daemon`     (scanner service active)
  #   - `systemctl status clamav-freshclam`  (definitions auto-updating)
  #   - a dated scan log:  clamscan -ri ~ | tee ~/clamscan-$(date +%F).log
  #
  # Scope chosen: daemon + auto-updating definitions only. No on-access
  # (clamonacc) scanning and no scheduled scans -- run scans manually as needed.
  #
  # First run: clamd won't start until a virus database exists. After `ns`,
  # populate it once with `sudo freshclam`, then `sudo systemctl restart clamav-daemon`.
  environment.systemPackages = [ pkgs.clamav ];

  services.clamav = {
    daemon.enable = true; # clamd -- keeps signatures loaded for fast scans
    updater.enable = true; # freshclam -- auto-updates virus definitions
  };
}
