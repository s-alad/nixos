{ nixpkgs-stable }:

# Workarounds for packages that are broken on nixos-unstable.
# Each entry should record:
#   - what's broken
#   - why
#   - the remediation (pin to stable / disable test / hash override / etc.)
#   - upstream PR / fix-in-flight if known
#
# Revisit on each `nu` (full input update) to see what can be removed.

[
  # linux-firmware + sof-firmware: pinned to stable to avoid iwlwifi BE201
  # firmware timeouts, SW resets, and stuck queues on the Intel Wi-Fi 7 BE201.
  # Also avoids SOF topology ABI mismatches with the pinned CachyOS kernel.
  (final: prev: {
    linux-firmware = nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}.linux-firmware;
    sof-firmware = nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}.sof-firmware;
  })

  # wangle: disable flaky TLSInMemoryTicketProcessorTest (timing-sensitive,
  # fails in the nix sandbox).
  (final: prev: {
    wangle = prev.wangle.overrideAttrs (old: {
      doCheck = false;
    });
  })

  # edencommon: disable flaky Fixture.lookup_expires test (process name race
  # in the nix sandbox).
  (final: prev: {
    edencommon = prev.edencommon.overrideAttrs (old: {
      doCheck = false;
    });
  })

  # mozillavpn 2.35.0: doesn't compile against Qt 6.11 — uses the deprecated
  # QQmlPropertyMap(QObject*) ctor and treats deprecation warnings as errors.
  # Upstream 2.36.0 fixes this; nixpkgs PR #513478 is in flight.
  # Pin to stable until the bump lands on unstable.
  (final: prev: {
    mozillavpn = nixpkgs-stable.legacyPackages.${prev.stdenv.hostPlatform.system}.mozillavpn;
  })

  # wireshark 4.6.5: the gitlab tarball gzip wrapper isn't byte-stable, so the
  # hash committed in nixpkgs (sha256-U30OJ8m+...) no longer matches what
  # gitlab serves. Override with the currently-served hash.
  (final: prev: {
    wireshark-cli = prev.wireshark-cli.overrideAttrs (old: {
      src = old.src.overrideAttrs (_: {
        outputHash = "sha256-Zvrwxjp4LK2J3QnxmPxKKrU01YHQvPyp54UWzeGNCjA=";
      });
    });
    wireshark = prev.wireshark.overrideAttrs (old: {
      src = old.src.overrideAttrs (_: {
        outputHash = "sha256-Zvrwxjp4LK2J3QnxmPxKKrU01YHQvPyp54UWzeGNCjA=";
      });
    });
  })
]
