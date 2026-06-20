{ config, pkgs, lib, ... }:

# ── Fan control for the compute box (Ryzen 7 5800X + RTX 3080 Ti, custom water loop) ──
#
# Drives the radiator/chassis fans off COOLANT temperature so they idle quiet and
# ramp only when the loop warms — a curve the Gigabyte BIOS can't do (no coolant sensor).
#
# Hardware discovered + probed live on the box (192.168.1.251):
#   • Fans are all on ONE Gigabyte motherboard header = it8688 **pwm4** (a hub/splitter;
#     1366 RPM @ 23% … 5232 RPM @ 100%). Headers 1/2/3/5 are empty.
#   • Fan START threshold ≈ pwm 60 (23%); below that it sits stalled at 0 RPM. The
#     BIOS "automatic" curve pinned it at pwm 42 (16%) → never spun, even at 70 °C CPU.
#     => we MUST drive it in MANUAL mode with a floor ≥ 60.
#   • Coolant temp: High Flow Next "Coolant temp" (inline, always present) with the
#     D5 Next "Coolant temp" as fallback — via the aquacomputer driver (loaded at boot).
#   • The Gigabyte IT8688E is only bindable by the OUT-OF-TREE it87 fork; the in-kernel
#     it87 (same module name, xz-compressed) wins `modprobe` and fails — so we insmod
#     the fork by exact store path. (See it87-fork service below.)

let
  it87Fork = config.boot.kernelPackages.it87;
  kver     = config.boot.kernelPackages.kernel.modDirVersion;
  it87Ko   = "${it87Fork}/lib/modules/${kver}/kernel/drivers/hwmon/it87.ko";
in
{
  # ── 1. Expose the IT8688E motherboard fan headers via the it87 fork ─────────
  boot.extraModulePackages = [ it87Fork ];

  systemd.services.it87-fork = {
    description = "Load out-of-tree it87 fork (Gigabyte IT8688E) for fan PWM";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # hwmon_vid is the fork's only dep; insmod won't auto-resolve it.
      # '-' on rmmod tolerates "not loaded" on a clean boot.
      ExecStartPre = [
        "-${pkgs.kmod}/bin/rmmod it87"
        "${pkgs.kmod}/bin/modprobe hwmon_vid"
      ];
      ExecStart = "${pkgs.kmod}/bin/insmod ${it87Ko} ignore_resource_conflict=1";
      ExecStop  = "-${pkgs.kmod}/bin/rmmod it87";
    };
  };

  # ── 2. Coolant-temp → pwm4 fan curve (the actual control loop) ──────────────
  # hwmon indices are NOT stable across boots, so the script resolves chips by
  # NAME every tick. Fail-safe: if the coolant sensor can't be read, fans go to a
  # SAFE 62% — never off. The floor (pwm 60, ~1370 RPM) keeps the fan above its
  # stall point, so even the lowest commanded value cools the loop.
  systemd.services.coolant-fan = {
    description = "Coolant-temperature fan curve for it8688 pwm4";
    wantedBy = [ "multi-user.target" ];
    after    = [ "it87-fork.service" ];
    wants    = [ "it87-fork.service" ];
    path     = [ pkgs.coreutils ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = 5;
    };
    script = ''
      set -u
      find_hwmon() {
        for h in /sys/class/hwmon/hwmon*; do
          [ "$(cat "$h/name" 2>/dev/null)" = "$1" ] && { echo "$h"; return 0; }
        done
        return 1
      }
      read_coolant_mC() {            # prefer inline High Flow Next, then D5 Next
        for chip in highflownext d5next; do
          h=$(find_hwmon "$chip") || continue
          v=$(cat "$h/temp1_input" 2>/dev/null)
          if [ -n "$v" ] && [ "$v" -gt 0 ] 2>/dev/null; then echo "$v"; return 0; fi
        done
        return 1
      }
      while true; do
        fan=$(find_hwmon it8688) || { sleep 5; continue; }   # it87 not up yet
        echo 1 > "$fan/pwm4_enable" 2>/dev/null              # manual mode
        if mc=$(read_coolant_mC); then
          t=$(( mc / 1000 ))
          if   [ "$t" -ge 42 ]; then pwm=255   # 100%
          elif [ "$t" -ge 40 ]; then pwm=200   # 78%
          elif [ "$t" -ge 38 ]; then pwm=160   # 62%
          elif [ "$t" -ge 36 ]; then pwm=135   # 53%
          elif [ "$t" -ge 34 ]; then pwm=110   # 43%
          elif [ "$t" -ge 32 ]; then pwm=90    # 35%
          elif [ "$t" -ge 30 ]; then pwm=75    # 29%
          else                       pwm=60    # 23% floor (~1370 RPM, never stalls)
          fi
        else
          pwm=160                              # sensor unreadable -> SAFE 62%
        fi
        echo "$pwm" > "$fan/pwm4" 2>/dev/null
        sleep 5
      done
    '';
  };

  # CoolerControl removed: the declarative service above is the single fan
  # controller (two controllers would fight over pwm4). Re-add
  # `programs.coolercontrol.enable = true;` later if you want graphs — just don't
  # let it drive pwm4. lm-sensors kept for `sensors` / hwmon introspection.
  environment.systemPackages = [ pkgs.lm_sensors ];
}
