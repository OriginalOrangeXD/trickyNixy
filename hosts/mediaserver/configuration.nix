{ config, pkgs, lib, ... }:

# Base NixOS configuration for the media server at 192.168.1.10.
#
# Foundation only. Storage (sdb, 12.7T), TrueNAS migration, ZFS, and any
# media services (jellyfin, *arr, etc.) are deferred — they land in later
# modules once the base is verified.
#
# Deploy from the laptop:
#   nixos-rebuild switch \
#     --flake .#mediaserver \
#     --target-host robby@192.168.1.10 \
#     --build-host  robby@192.168.1.10 \
#     --use-remote-sudo \
#     --ask-sudo-password           # first deploy only; future deploys hands-free
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/mosh.nix
  ];

  # ── Nix settings ────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Opportunistic GC + store optimisation. The root disk is 3.6T but the
  # media-server life cycle will fill it; freeing weekly prevents fights later.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # ── Identity ────────────────────────────────────────────────────────────
  networking.hostName = "mediaserver";
  networking.useDHCP  = lib.mkDefault true;

  time.timeZone      = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  services.xserver.xkb = {
    layout  = "us";
    variant = "";
  };

  # ── Bootloader ──────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Deploy user (target of `nixos-rebuild --target-host robby@…`) ───────
  users.users.robby = {
    isNormalUser = true;
    description  = "Robert (deploy / admin)";
    extraGroups  = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG7WQgXfplk8FlV5CgyKxHaLRpTMtJcyct3s6ADdOYJ9 robby@Roberts-MacBook-Pro.local"
    ];
  };

  # Passwordless sudo for the wheel group so future deploys are hands-free.
  security.sudo.wheelNeedsPassword = false;

  # ── SSH ─────────────────────────────────────────────────────────────────
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  # ── Firewall ────────────────────────────────────────────────────────────
  # 22 ssh — that's it for the base system. Media-service ports get added
  #          per-module when the services land.
  networking.firewall.allowedTCPPorts = [ 22 ];

  # ── IPv6 address-selection fix ──────────────────────────────────────────
  # This LAN hands out ULA IPv6 (fdeb:…/64) via SLAAC but has NO global IPv6
  # uplink, so any IPv6 connection to the internet dies with a reset. Dual-
  # stacked sites (Cloudflare-fronted trackers like 1337x) publish AAAA
  # records, and glibc's default RFC 3484 ordering prefers IPv6 — so Prowlarr
  # (.NET) tries the dead AAAA first and fails with HTTP/2 PROTOCOL_ERROR.
  # Bumping IPv4-mapped precedence makes getaddrinfo return IPv4 first.
  # We deliberately do NOT disable IPv6 system-wide: the wg_client killswitch
  # namespace assigns an IPv6 address to wg0 under `set -e`, so a global
  # disable could break the VPN bring-up. This only changes resolution order.
  environment.etc."gai.conf".text = "precedence ::ffff:0:0/96  100\n";

  # ── System packages (foundation only) ───────────────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    neovim
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
  ];

  # stateVersion matches the live install on the box (verified via
  # /etc/os-release: BUILD_ID=25.11.10134.…). Never bump without a real
  # migration plan.
  system.stateVersion = "25.11";
}
