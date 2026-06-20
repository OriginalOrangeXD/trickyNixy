{ config, pkgs, lib, ... }:

let
  # Wrapper that drops ambient + inheritable caps before exec'ing Steam.
  # gamescope (with cap_sys_nice+ep on its wrapper) is able to put cap_sys_nice
  # into its own ambient set via capset()+prctl(PR_CAP_AMBIENT_RAISE), and that
  # ambient cap propagates across exec to Steam → bwrap → "Unexpected
  # capabilities but not setuid" abort. setpriv lowering one's OWN caps needs
  # no privilege (prctl(PR_CAP_AMBIENT_LOWER) is unprivileged), so this
  # wrapper just nukes the inherited caps and exec's the real Steam binary.
  steamLaunchScript = pkgs.writeShellScript "gamebox-steam-launch" ''
    exec ${pkgs.util-linux}/bin/setpriv \
      --inh-caps=-all --ambient-caps=-all \
      -- /run/current-system/sw/bin/steam
  '';
in

# Minimal Jovian Steam Deck UI per
# https://github.com/Jovian-Experiments/Jovian-NixOS/blob/development/docs/configuration.md
#
# Jovian's docs are intentionally tiny — "other computers are just boring
# computers." For a non-Deck AMD-GPU desktop the recipe is essentially three
# Jovian options plus standard NixOS. We add the absolute minimum on top of
# that for the specific facts of this box:
#   - headless: force HDMI-A-1 connected at 1080p60 so gamescope has a CRTC
#   - Sunshine VA-API encode path: provided in modules/sunshine.nix
#
# We do NOT enable: useSteamOSConfig, decky-loader, any *full* desktop manager,
# custom kernel, BORE sysctls, Proton/Gamescope env vars, zramSwap, or
# appimage. Each of those is its own additive ask; introduce later one at a
# time only when there's a concrete reason and after closure-check.
#
# AUTOSTART MODEL (revised 2026-05-29):
# Jovian's autoStart=true used to handle this — SDDM + gamescope-session +
# Deck UI all the way through. We dropped autoStart because the Deck UI's
# periodic firmware-updater poll calls /usr/bin/steamos-polkit-helpers/
# jupiter-biosupdate which doesn't exist inside the stock Steam FHS bwrap
# (jovian-stubs don't land there unless `pkgs.steam-jupiter` is used). The
# missing-file failure surfaces in the UI as
# "Updater apply error: 2: null" / "unable to download the required update (2)".
# So instead of Jovian's autoStart, we use greetd as a featherweight login
# manager that auto-logs robby into a plain `gamescope -- steam` session
# (no -steamdeck / -steamos3 / -gamepadui flags). This:
#   - gives Sunshine a Wayland session + KMS source to capture
#   - keeps the desktop Steam UI (NOT Deck UI), so no biosupdate poll
#   - survives reboot without manual SSH-launch
# If gamescope/steam exits, greetd respawns it (Restart=on-failure).
{
  # Steam EULA + redistributable GPU firmware are unfree.
  nixpkgs.config.allowUnfree = true;

  jovian = {
    steam.enable    = true;
    steam.autoStart = false;
    steam.user      = "robby";
  };
  # GPU stack (hardware.graphics + Mesa + 32-bit libs OR NVIDIA driver) is
  # the per-host's responsibility — gamebox sets `jovian.hardware.has.amd.gpu`,
  # aibox imports modules/nvidia.nix. Keeping this module GPU-agnostic lets
  # the same Steam/gamescope/Sunshine stack run on both AMD and NVIDIA hosts.

  # Headless virtual display. Forces HDMI-A-1 on at 1080p60 even with no
  # monitor attached (the trailing `D` = force-connected). One virtual output
  # serves as the gamescope render surface AND the Sunshine KMS-capture
  # source.
  boot.kernelParams = [ "video=HDMI-A-1:1920x1080@60D" ];

  # ── System seatd (NEW 2026-05-29) ──────────────────────────────────────────
  # gamescope uses libseat for VT/DRM access. Without a system seatd, it falls
  # back to its embedded seatd backend, which needs root caps it doesn't have
  # — fails with "Could not open target tty: Permission denied" and "client is
  # not active" before even opening the KMS device. Enabling services.seatd
  # gives gamescope a system seatd to talk to; robby needs to be in the `seat`
  # group AND on the active VT (tty1 autologin) for the seatd `active` check
  # to pass.
  services.seatd.enable = true;
  users.users.robby.extraGroups = [ "seat" ];

  # ── Realtime priority for gamescope (revised 2026-05-30) ───────────────────
  # First attempt (chrt --fifo --reset-on-fork) failed: gamescope checks for
  # CAP_SYS_NICE on its own binary at startup and explicitly RESETS itself
  # to SCHED_OTHER if it doesn't see the cap ("No CAP_SYS_NICE, falling back
  # to regular-priority compute and threads.") — even if we externally set
  # SCHED_FIFO. So we have to give gamescope the cap.
  #
  # The trick is the cap mode. Jovian's default is `cap_sys_nice+pie`
  # (permitted/inheritable/effective) — the +i means gamescope's
  # `prctl(PR_CAP_AMBIENT_RAISE, CAP_SYS_NICE)` succeeds, the cap leaks into
  # the ambient set, propagates across exec to Steam → bwrap → "Unexpected
  # capabilities but not setuid".
  #
  # Force the cap to `+ep` (permitted+effective only). Without inheritable,
  # the prctl ambient-raise FAILS (a cap must be in BOTH permitted AND
  # inheritable to be raised to ambient). Gamescope still has the cap in
  # permitted+effective so it self-bumps SCHED_FIFO; nothing reaches the
  # ambient set; Steam's bwrap sees zero caps; everyone wins.
  security.wrappers.gamescope.capabilities = lib.mkForce "cap_sys_nice+ep";

  # rtkit and pam loginLimits are belt-and-suspenders: other compositor
  # binaries or audio paths may want them, and they don't cost anything
  # if gamescope is the only thing using realtime.
  security.rtkit.enable = true;
  security.pam.loginLimits = [
    { domain = "robby"; type = "-"; item = "rtprio";  value = "95"; }
    { domain = "robby"; type = "-"; item = "nice";    value = "-15"; }
    { domain = "robby"; type = "-"; item = "memlock"; value = "unlimited"; }
  ];

  # ── getty autologin → gamescope → plain Steam ──────────────────────────────
  # NixOS kiosk pattern: getty autologs robby into tty1; /etc/profile checks
  # for tty1 + no existing graphical session, then exec's gamescope wrapping
  # plain Steam. /run/wrappers/bin/gamescope carries cap_sys_nice via Jovian's
  # security.wrappers.gamescope. No -steamdeck flag → no Deck UI → no
  # biosupdate poll → no "(2)" dialog. The systemctl --user start of
  # graphical-session.target is what brings up the Sunshine user unit
  # (Sunshine has WantedBy=graphical-session.target).
  #
  # The guard is essential: environment.loginShellInit fires on every login
  # on every TTY (including SSH); without the tty1+no-DISPLAY check, ssh-ing
  # in would replace your shell with gamescope and break recovery.
  services.getty.autologinUser = "robby";

  environment.loginShellInit = lib.mkAfter ''
    if [ "$USER" = "robby" ] \
        && [ "$(tty)" = "/dev/tty1" ] \
        && [ -z "$WAYLAND_DISPLAY" ] \
        && [ -z "$DISPLAY" ]; then
      # Sunshine has WantedBy=graphical-session.target but that meta-target
      # refuses manual start ("may be requested by dependency only").
      # Start sunshine directly — it'll see gamescope's wayland-0 socket
      # and capture from there.
      systemctl --user start sunshine || true
      # Use the WRAPPED gamescope (/run/wrappers/bin/gamescope) for cap_sys_nice
      # so it can self-bump to SCHED_FIFO. Wrap Steam in the setpriv launch
      # script (defined in the `let` block above) to nuke ambient/inheritable
      # caps before Steam's bwrap sees them. Output to
      # /tmp/gamescope-autostart.log for diagnosis.
      #
      # NVIDIA + gamescope atomic-commit workarounds:
      #   WLR_DRM_NO_ATOMIC=1 (env) — wlroots backend uses legacy page-flip
      #   --disable-layers (flag)  — disables libliftoff (hardware planes);
      #                              without this NVIDIA floods drmModeAtomic-
      #                              Commit EACCES even with WLR_DRM_NO_ATOMIC,
      #                              because liftoff issues its own atomic
      #                              commits above wlroots
      # Env vars set inline because environment.sessionVariables writes
      # /etc/profile.d/*.sh which is sourced AFTER this exec fires. AMD
      # hosts pay a small perf cost (no multi-plane scanout) but otherwise
      # work fine with both knobs flipped — acceptable for the console role.
      exec env WLR_DRM_NO_ATOMIC=1 \
        /run/wrappers/bin/gamescope \
        -W 1920 -H 1080 -r 60 \
        --disable-layers \
        -- ${steamLaunchScript} &> /tmp/gamescope-autostart.log
    fi
  '';

  # ── Hide DualSense from Steam Input grab (NEW 2026-05-30) ──────────────────
  # Steam Input claims PS5 controllers via hidraw (SDL_JOYSTICK_DISABLE_UDEV=1
  # on every Steam process) and applies basicui_neptune.vdf Deck-mode bindings
  # that map the PS button to "Steam button" → toggle Deck UI overlay. The
  # symptom of a flaky USB-connected DualSense (cable resending HID reports,
  # touchpad/PS button stuck, stick drift past Steam's deadzone) is a rapid
  # overlay flicker — the Steam-button binding ping-pongs the side menu on/off.
  # Confirmed because opening the Steam OSK absorbs the loop into keyboard-nav.
  #
  # Making all three of the DualSense's device-node classes (hidraw, js, event)
  # root-only with `MODE="0600"` and stripping the `uaccess` tag prevents
  # Steam Input (running as robby) from opening any of them. The controller
  # is effectively invisible to userspace; it still charges over USB.
  # Reclaim by removing this block. Moonlight's virtual gamepad delivers
  # controller input from the stream regardless.
  services.udev.extraRules = ''
    # Sony DualSense (PS5) — vendor 054c, product 0ce6
    SUBSYSTEM=="hidraw",  ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0600", OWNER="root", GROUP="root", TAG-="uaccess"
    KERNEL=="js[0-9]*",   ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0600", OWNER="root", GROUP="root", TAG-="uaccess"
    KERNEL=="event[0-9]*",ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0600", OWNER="root", GROUP="root", TAG-="uaccess"
  '';
}
