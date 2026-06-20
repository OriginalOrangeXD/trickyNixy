{ config, pkgs, lib, ... }:

# Base NixOS configuration for the AI box at 192.168.1.251.
#
# Role: second console intended to reproduce-or-rule-out the controller
# flicker we saw on gamebox, on different hardware:
#
#   gamebox  →  AMD Radeon RX 5700 (Navi 10) + Jovian/gamescope/SteamDeck-UI
#   aibox    →  NVIDIA GeForce RTX 3080 Ti (GA102, Ampere) + X11 + Steam
#                                                          Big Picture
#
# We do NOT use gamescope here because NVIDIA's KMS atomic path is broken
# for libliftoff (gamescope's plane-composition layer) in ways we couldn't
# unblock — even with the open kernel module, nvidia-drm.fbdev=1, and
# --disable-layers, drmModeAtomicCommit floods EACCES and frames never reach
# the display. X11 on NVIDIA is rock-solid; Sunshine captures X11 natively.
# Structurally different from gamebox, but isolates the variable that
# matters: whether Steam Input + DualSense behaviour reproduces on
# non-AMD hardware.
#
# AMD Ryzen 7 5800X, 62 GB RAM, Samsung 980 Pro 1 TB NVMe, HDMI-A-1 connected.
#
# Deploy from the laptop (build-host = target-host because the aarch64-darwin
# laptop cannot build x86_64-linux):
#   nixos-rebuild switch \
#     --flake .#aibox \
#     --target-host robby@192.168.1.251 \
#     --build-host  robby@192.168.1.251 \
#     --sudo
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/mosh.nix
  ];

  # ── Nix settings ────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Game/Proton/shader caches grow fast; free weekly so the NVMe lasts.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # ── Identity ────────────────────────────────────────────────────────────
  networking.hostName = "aibox";
  networking.networkmanager.enable = true;

  time.timeZone      = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  services.xserver.xkb = {
    layout  = "us";
    variant = "";
  };

  # ── Bootloader ──────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── NVIDIA tuning for X11 + Steam ────────────────────────────────────────
  # nvidia-drm.modeset=1 enables proper KMS modeset; required so X.Org's
  # NVIDIA driver and Sunshine's capture path see a real DRM framebuffer.
  # nvidia-drm.fbdev=1 makes NVIDIA attach as the kernel framebuffer driver.
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
  ];

  # ── Forza Horizon 6 / DX12-Ultimate crash fixes (Xid 109) ────────────────
  # dmesg from gameplay shows repeating
  #   NVRM: Xid 109 errorString CTX SWITCH TIMEOUT, name=forzahorizon6.e
  # That's the closed-driver context-switch timeout firing — Forza's
  # VKD3D-Proton dispatch pattern bursts compute/graphics work faster than
  # the driver's preemption path can keep up. Two-line fix:
  #
  # 1. `nvidiaPersistenced = true`  — runs nvidia-persistenced, which
  #    holds the GPU in the P0 power state. Without it the driver can drop
  #    into lower P-states between dispatches; restoring takes long enough
  #    that the next dispatch trips the CTX_SWITCH_TIMEOUT watchdog. P0 lock
  #    eliminates that race entirely.
  #
  # 2. `open = lib.mkForce true`    — switch to the open kernel module.
  #    Its context-switch and preemption code paths are rewritten relative
  #    to the closed module and Xid 109 is rare-to-absent on Ampere. The
  #    lib.mkForce keeps mediaserver on the closed module (Jellyfin NVENC
  #    doesn't care about display/context, so leaving it alone).
  hardware.nvidia.nvidiaPersistenced = true;
  hardware.nvidia.open = lib.mkForce true;

  # ── X11 + Steam Big Picture autostart ────────────────────────────────────
  # SDDM auto-logs robby into a custom "steam-bigpicture" X session whose
  # ExecStart launches Steam directly. No window manager, no desktop — the
  # Steam window IS the session. Sunshine captures X11 natively, so frames
  # reach the encoder cleanly even though there's no compositor in between.
  # If Steam exits, SDDM returns to a login screen (which auto-logs back in,
  # restarting the session). This is the canonical NVIDIA-on-Linux kiosk
  # pattern.
  programs.steam.enable = true;

  services.xserver = {
    enable        = true;
    videoDrivers  = [ "nvidia" ];   # match modules/nvidia.nix
  };

  services.displayManager = {
    autoLogin = {
      enable = true;
      user   = "robby";
    };
    sddm.enable = true;
    # "none+steam-bigpicture" = no desktop manager + our window-manager session.
    # NixOS builds session names as "<desktopManager>+<windowManager>".
    defaultSession = "none+steam-bigpicture";
  };

  # Session entry: openbox as a tiny WM (~700KB) so Steam's
  # _NET_WM_STATE_FULLSCREEN request is honored — without ANY WM, Steam
  # opens as a regular floating window even with -tenfoot. openbox runs
  # backgrounded; Steam in -tenfoot mode auto-fullscreens on launch.
  # The session ends when Steam exits, SDDM relogs robby, restart cycle.
  services.xserver.windowManager.session = lib.singleton {
    name  = "steam-bigpicture";
    start = ''
      ${pkgs.openbox}/bin/openbox &
      exec ${pkgs.steam}/bin/steam -tenfoot
    '';
  };

  # ── DualSense udev rule (carried over from gamebox investigation) ───────
  # The PS5 controller's hidraw and joystick nodes get root-only mode so
  # Steam Input cannot grab it via hidraw and apply Deck-mode overlay-
  # toggle bindings. Useful as a precaution if you plug a DualSense into
  # this box for the test — Steam Input still sees the Moonlight virtual
  # gamepad, which is what we actually want to drive the test from.
  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw",  ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0600", OWNER="root", GROUP="root", TAG-="uaccess"
    KERNEL=="js[0-9]*",   ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0600", OWNER="root", GROUP="root", TAG-="uaccess"
    KERNEL=="event[0-9]*",ATTRS{idVendor}=="054c", ATTRS{idProduct}=="0ce6", MODE="0600", OWNER="root", GROUP="root", TAG-="uaccess"
  '';

  # ── Deploy user (target of `nixos-rebuild --target-host robby@…`) ────────
  # Same ed25519 key as the other hosts so the laptop authenticates cleanly.
  users.users.robby = {
    isNormalUser = true;
    description  = "Robert (deploy / admin)";
    extraGroups  = [ "wheel" "networkmanager" "video" "render" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG7WQgXfplk8FlV5CgyKxHaLRpTMtJcyct3s6ADdOYJ9 robby@Roberts-MacBook-Pro.local"
    ];
  };

  # Passwordless sudo for `wheel` so deploys after the first are hands-free.
  security.sudo.wheelNeedsPassword = false;

  # ── SSH ─────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  # ── Firewall ──────────────────────────────────────────────────────────────
  networking.firewall.allowedTCPPorts = [ 22 ];

  # ── IPv6 address-selection fix (same LAN-wide ULA-IPv6 trap as the other
  #    hosts) ──────────────────────────────────────────────────────────────
  environment.etc."gai.conf".text = "precedence ::ffff:0:0/96  100\n";

  # ── Hold the graphical session until the network is online ──────────────
  # Same rationale as gamebox: Steam's first manifest fetch dies on
  # `http error 0` if the network isn't ready when the autostart fires.
  systemd.services.display-manager = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
  };

  # ── System packages (admin + GPU/stream diagnostics) ─────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    btop
    tmux
    fastfetch
    pciutils
    usbutils
    lsof
    file
    tree
    rsync
    bun
    nvtopPackages.nvidia # NVIDIA GPU monitor (vs amd on gamebox)
    vulkan-tools
    evtest
    libinput
  ];

  # stateVersion matches the live install on the box (verified 26.05).
  system.stateVersion = "26.05";
}
