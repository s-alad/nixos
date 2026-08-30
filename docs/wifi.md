# Wi-Fi (Intel BE201) — Stability Notes

## TL;DR

The BE201 wifi card crashes its own firmware (`NMI_INTERRUPT_UNKNOWN` → `Device error - SW reset`) every few minutes under load. Each crash drops the link for several seconds and feels like the whole machine froze. The fix is to disable TCP/Generic Segmentation Offload on the wifi interface so the buggy TX offload path in the firmware is never exercised. Done declaratively via a NetworkManager dispatcher in `modules/system/wifi-offload-fix.nix`.

## Hardware / driver state

- **Card:** Intel Wi-Fi 7 BE201, PCI ID `8086:7740` (Arrow Lake CNVi, "BZ-b0" silicon)
- **Driver:** `iwlwifi` with op_mode `iwlmld` (mandatory — BZ silicon has no `iwlmvm` firmware)
- **Firmware loaded:** `bz-b0-fm-c0-c101.ucode` version `101.6e695a70.0`
- **Interface:** `wlp0s20f3`
- **Kernel:** 7.1.1-cachyos
- **BIOS:** Lenovo N4EET19W (1.05) — current as of Sept 2025

## Symptoms

In `journalctl -k`, repeated bursts like:

```
iwlwifi 0000:00:14.3: Error sending SYSTEM_STATISTICS_CMD: time out after 2000ms.
iwlwifi 0000:00:14.3: 0x00000084 | NMI_INTERRUPT_UNKNOWN
iwlwifi 0000:00:14.3: 0x20000066 | NMI_INTERRUPT_HOST
iwlwifi 0000:00:14.3: Device error - SW reset
iwlwifi 0000:00:14.3: restart completed
```

User-visible: browser tabs hang, SSH sessions stall, syncthing/docker pulls pause for several seconds. The system itself is **not** crashing — only the wifi firmware NMIs and SW-resets. Frequency increases under TX-heavy workloads (uploads, container image pushes).

## Root cause

Open upstream regression in the new `iwlmld` driver path on `bz-b0-fm-c0-c101` firmware. The firmware faults when handed offloaded TX commands (TSO / GSO / TX checksum). The TX-command-id signature (`0x048D001C`) and `trm_hw_status0=0x000002F0` match the open report at https://github.com/CachyOS/linux-cachyos/issues/673 (same card, same firmware, same NMI fingerprint).

## Things that did NOT help

These were tried before landing on the offload fix — don't waste time on them again:

- `power_save=0` — already on, doesn't change anything
- `disable_11be=1` (kill Wi-Fi 7) — already on, NMIs continued
- `disable_11ax=1` (kill Wi-Fi 6) — same firmware path is exercised, no help
- `swcrypto=1` — already on
- Forcing `iwlmvm` op_mode — **not possible**: BZ-b0 silicon ships mld-only firmware, no mvm path exists
- Newer firmware (`c102`, `c103` are present on disk) — your kernel's `iwlwifi.ko` only advertises API up to `c101`, so newer files are ignored until the in-tree driver bumps `IWL_*_UCODE_API_MAX`
- BIOS update — N4EET19W 1.05 is the current Lenovo release for the P1 Gen 8 (21Q8/21Q9), no newer one addresses BE201
- Pinning `linux-firmware` to nixos-stable — already done in `flake.nix` overlay; pre-existing crashes still occur because `c101` is what loads regardless

## The fix

`modules/system/wifi-offload-fix.nix` installs a NetworkManager dispatcher script. When `wlp0s20f3` transitions to `up` (boot, suspend resume, AP change), the script runs:

```
ethtool -K wlp0s20f3 tso off gso off tx off
```

This disables:

- **TSO** (TCP Segmentation Offload) — the kernel handed large TCP segments to the card to chop up; now the kernel does it
- **GSO** (Generic Segmentation Offload) — same idea, generic
- **TX checksum offload** — the kernel computes TX checksums itself instead of delegating

The result: the buggy firmware code paths are never reached.

### Why a dispatcher and not a oneshot

The kernel resets the offload flags every time the link bounces (suspend/resume, roaming, reconnect). A `systemd` oneshot at boot would only cover the boot case. NetworkManager's dispatcher fires on every state transition, so the workaround is reapplied automatically.

## Cost

- **Performance:** small CPU bump on heavy uploads — TCP segmentation moves from the wifi card to the i9. Unmeasurable in normal use.
- **Latency / range / Wi-Fi 7 features:** unchanged.
- **Power:** marginally higher CPU use during sustained uploads. Not noticeable on AC; trivial on battery.

## Verifying it's active

```bash
ethtool -k wlp0s20f3 | grep -E "tso|gso|tx-checksum"
```

Should show:

```
tx-checksumming: off
tcp-segmentation-offload: off
generic-segmentation-offload: off
```

And to confirm no new NMIs since rebuild:

```bash
journalctl -k -b 0 | grep -c "Device error - SW reset"
```

Number stops incrementing once the dispatcher kicks in.

## Going back to a stable default (removing this workaround)

This module is a regression workaround. The plan is to delete it once upstream is fixed. This section is the playbook.

### Step 1: figure out if the fix has landed

There are two independent ways the upstream bug can be resolved. Either is sufficient.

**A. Kernel-side `iwlmld` fix.** The driver gets patched so it no longer hands offloaded TX to the buggy firmware path (or the driver gates offload on a known-good firmware version).

How to check:

```bash
# what kernel are you on right now?
uname -r

# search for iwlmld TX/offload fixes since c101 firmware (April 2026)
# look for keywords: "iwlmld", "BE201", "TSO", "offload", "NMI"
```

Watch these:

- https://lore.kernel.org/linux-wireless/?q=iwlmld+BE201 — primary mailing list
- https://lore.kernel.org/linux-wireless/?q=iwlmld+offload — broader offload-related fixes
- https://github.com/CachyOS/linux-cachyos/issues/673 — the bug we filed under; will get a `closed` status when upstream lands a fix
- https://git.kernel.org/pub/scm/linux/kernel/git/iwlwifi/iwlwifi-next.git/log/ — iwlwifi maintainer tree, look at TX/MLD-area commits

**B. Driver picks up newer firmware.** Intel ships `c102`/`c103` already (visible in `/run/current-system/firmware/iwlwifi-bz-b0-fm-c0-c10*.ucode.zst`), but the in-tree `iwlwifi.ko` advertises an API max of `c101`, so the newer files are ignored. When the driver bumps that constant, the next-newest matching firmware is loaded automatically.

How to check what the driver is actually loading right now:

```bash
journalctl -k -b 0 | grep "loaded firmware version"
# expect line like: "loaded firmware version 101.6e695a70.0 bz-b0-fm-c0-c101.ucode op_mode iwlmld"
# the workaround can be removed when this reads c102 or higher AND that firmware
# has been out for >2 weeks without a regression report on linux-wireless
```

If you want to know what the driver's API max is in the running kernel:

```bash
modinfo iwlwifi | grep -i "firmware:" | grep "bz-b0-fm-c0"
# the highest numbered file listed is the highest API the driver supports
```

### Step 2: regression test before deleting

Before removing the workaround, simulate a no-workaround state in-place to make sure the new kernel/firmware is actually fixed:

```bash
# disable the workaround temporarily (does NOT survive reboot or link bounce)
sudo ethtool -K wlp0s20f3 tso on gso on tx on

# stress the TX path that triggers the firmware NMI:
#   - any large upload works. Examples:
#     docker push <a multi-GB image>
#     rsync -av <large local dir> remote:/tmp/
#     iperf3 -c <server> -t 600 -P 4    # 10 min, 4 parallel streams

# in another terminal, watch for the bug recurring:
journalctl -k -f | grep -E "Device error - SW reset|NMI_INTERRUPT"
```

Run this for at least 30 minutes of sustained TX with offloads back on. If zero `Device error - SW reset` lines appear during that window, the upstream fix is real. If even one shows up, **do not remove the workaround** — re-enable offloads off and wait longer.

### Step 3: remove the workaround

Once Step 2 passes:

1. Remove the import line from `hosts/salad/configuration.nix` (the line `../../modules/system/wifi-offload-fix.nix` in the `imports` list).
2. Delete `modules/system/wifi-offload-fix.nix`.
3. Optionally clean up the related modprobe flags in `configuration.nix` if you want to also re-enable Wi-Fi 7 — that is a *separate* check (test that `disable_11be=1` removal doesn't bring back a different firmware bug; see "Things that did NOT help" above for context — `disable_11be` was an earlier mitigation, not the load-bearing fix).
4. `ns` to rebuild.
5. Reboot, then re-run the Step 2 stress test for another 30 minutes to confirm stable on a clean boot.
6. If clean: update `wifi.md` (or delete it), update CLAUDE.md if it references this issue, update memory at `~/.claude/projects/-etc-nixos/memory/project_iwlwifi-be201-crashes.md` to mark resolved.

### Rollback (if removal turns out to be premature)

If NMIs return after removal:

```bash
# fast in-session rollback — no rebuild required
sudo ethtool -K wlp0s20f3 tso off gso off tx off
```

Then re-add the deleted module and the import line, `ns`, and you're back to the workaround state. Git history of `/etc/nixos` makes this trivial — `git log --all -- modules/system/wifi-offload-fix.nix` to find the commit, `git checkout <sha> -- <path>` to restore.

## If this doesn't fix it

If `journalctl -k -b 0 | grep "Device error - SW reset"` keeps incrementing after this is active, the next escalation is hardware replacement: pull the BE201 and drop in an Intel AX210 / AX211. The AX210 uses `iwlmvm` (mature, stable) and is the ThinkPad community's standard fix for BE-series instability on Linux. The P1 Gen 8 has no Lenovo wifi whitelist, so swap is straightforward. This is recommended only after giving the offload fix 24–48 hours under normal workload.

## References

- https://github.com/CachyOS/linux-cachyos/issues/673 — same fingerprint, TSO/GSO workaround confirmed
- https://bbs.archlinux.org/viewtopic.php?id=307897 — broader BE201 instability discussion (T14s Gen 6, similar firmware)
- https://bugs.launchpad.net/ubuntu/+source/linux-firmware/+bug/2113477 — earlier BE201 firmware regression (separate issue, but evidence Intel ships flaky BZ firmware repeatedly)
- https://www.spinics.net/lists/linux-wireless/msg261848.html — `iwlmld` introduction; explains why mvm is not an option for BZ silicon
- https://gitlab.com/kernel-firmware/linux-firmware/-/tree/main/intel/iwlwifi — upstream firmware tree
