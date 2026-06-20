{ config, lib, pkgs, ... }:

# ZFS support for the mediaserver. Phase A of the TrueNAS migration:
# enable ZFS without importing any pool yet (pool arrives at Phase C, after
# the physical disk move).
#
# Pool inventory after Phase C:
#   bare  — stripe of 3 single-disk vdevs (2 × 8TB IronWolf + 1 × 14TB WDC HC580)
#           ~27 TiB usable, NO REDUNDANCY (Robert's explicit choice).
#
# After Phase C completes, flip `boot.zfs.extraPools = [ "bare" ]` so the pool
# auto-imports on every boot (kept disabled now to avoid boot failures while
# the disks aren't physically present yet).
{
  # ── ZFS support ────────────────────────────────────────────────────────
  boot.supportedFilesystems = [ "zfs" ];
  boot.zfs.forceImportRoot  = false;        # root is on ext4 (/dev/sda2), not ZFS
  boot.zfs.extraPools = [ "bare" ];         # Phase D — auto-import on boot.

  # Kernel: nixpkgs's default kernel and bundled ZFS are aligned by the
  # nixpkgs maintainers — no pin needed today. (The historical
  # `boot.zfs.package.latestCompatibleLinuxPackages` helper was deprecated;
  # it just returns the default kernel. If a future eval starts failing with
  # a kernel/ZFS mismatch, pin explicitly to an LTS line:
  #   boot.kernelPackages = pkgs.linuxPackages_6_12;)

  # ── Host identity (REQUIRED by ZFS for pool-ownership safety) ───────────
  # 8 hex chars, must be stable for the lifetime of the box. Derived from the
  # first 8 chars of /etc/machine-id on this mediaserver (one-time bootstrap).
  # Changing this WILL prevent the pool from auto-importing without `-f`.
  networking.hostId = "ddc82828";

  # ── Maintenance ─────────────────────────────────────────────────────────
  services.zfs = {
    autoScrub = {
      enable    = true;
      interval  = "Sun *-*-* 03:00:00";   # weekly, Sunday 3 AM local
      pools     = [ "bare" ];             # no-op until pool imported
    };

    # TRIM is harmless on HDDs (no-op) and important if SSDs land here later.
    trim = {
      enable   = true;
      interval = "weekly";
    };

    # ZFS Event Daemon — keeps an eye on pool health. Email disabled until
    # there is a working mail relay on the box.
    zed.settings = {
      ZED_DEBUG_LOG       = "/var/log/zed.debug.log";
      ZED_NOTIFY_VERBOSE  = false;
    };
  };

  # ── Userland ────────────────────────────────────────────────────────────
  environment.systemPackages = with pkgs; [
    smartmontools          # smartctl — pre-flight health check before adding disks
    pv                     # progress on long-running zfs send / dd operations
  ];
}
