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

  # NOTE (2026-08-04): session-desktop is currently unbuildable on BOTH channels
  # and not in the binary cache, so it's temporarily removed (commented out in
  # home/salad.nix) rather than worked around here:
  #   - unstable 1.18.0: pnpm aborts with ERR_PNPM_MISSING_TARBALL_INTEGRITY
  #     (its lockfile entry for the @emoji-mart/data github-release tarball has
  #     no "integrity" field) during the fetch-deps phase.
  #   - stable 1.17.5 (from source): @signalapp/better-sqlite3 fails to compile
  #     against stable's Electron V8 ('v8::Object' has no member 'GetPrototype').
  # Re-add to home/salad.nix (and delete this note) once either channel builds.

  # NOTE (2026-06-22 audit): two workarounds removed after verifying they were no
  # longer needed on the current unstable:
  #   - mozillavpn stable-pin (was for the 2.35.0 / Qt 6.11 build failure; unstable
  #     is now 2.37.0, past the 2.36.0 fix).
  #   - wireshark src outputHash override (was for a non-byte-stable gitlab tarball;
  #     upstream 4.6.6's committed hash now resolves from cache.nixos.org).
]
