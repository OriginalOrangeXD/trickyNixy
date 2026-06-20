{ config, pkgs, lib, ... }:

# Base NixOS configuration for the agent box at 192.168.1.79.
#
# Role: plain Docker host for self-hosted agents. Containers are run by hand
# (`docker compose up -d`), not declared in Nix — the box just provides the
# engine and puts robby in the docker group. Reached over Tailscale (carried
# over from its former life as the `gamebox` SteamOS console); no LAN port-
# forwarding. AMD RX 5700 is present but not wired into containers (CPU-only).
#
# Deploy from the laptop (build-host = target-host because the aarch64-darwin
# laptop cannot build x86_64-linux):
#   nixos-rebuild switch \
#     --flake .#agentbox \
#     --target-host robby@192.168.1.79 \
#     --build-host  robby@192.168.1.79 \
#     --use-remote-sudo
{
  imports = [
    ./hardware-configuration.nix
  ];

  # ── Nix settings ────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # claude-code ships under Anthropic's unfree license; codex + opencode are
  # free, but the agent CLIs below need this flag for the Claude one to build.
  nixpkgs.config.allowUnfree = true;

  # Docker image/layer churn grows the store fast; free weekly so the 1.8T
  # NVMe lasts. (`docker system prune` handles dangling images separately.)
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # ── Identity ────────────────────────────────────────────────────────────
  networking.hostName = "agentbox";
  # The box was installed with NetworkManager; keep it (DHCP lease at .79).
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

  # ── Deploy user (target of `nixos-rebuild --target-host robby@…`) ────────
  # The ed25519 key below is the exact key currently authorized on the box and
  # the one the laptop authenticates with — reused verbatim so turning off
  # password auth cannot lock us out. `docker` group = manage containers
  # without sudo.
  users.users.robby = {
    isNormalUser = true;
    description  = "Robert (deploy / admin)";
    extraGroups  = [ "wheel" "networkmanager" "docker" ];
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

  # mosh: roaming SSH that survives IP changes / sleep. Installs the package and
  # opens its UDP 60000-61000 range (needed on the LAN; tailscale0 is already a
  # trusted interface so mosh over the tailnet works regardless).
  programs.mosh.enable = true;

  # ── Docker ────────────────────────────────────────────────────────────────
  # Plain engine; agents are run by hand via `docker compose`. The compose v2
  # plugin ships with the docker package. Weekly prune of dangling images keeps
  # the store from ballooning between nix-gc runs.
  virtualisation.docker = {
    enable = true;
    autoPrune = {
      enable = true;
      dates  = "weekly";
    };
  };

  # ── Tailscale: reach the box from anywhere, no LAN port-forwarding ─────────
  # Carried over from the gaming build. `tailscale0` is trusted so agent
  # services bound on the host are reachable to tailnet peers only. First run
  # is interactive: `sudo tailscale up` once to (re)authenticate.
  services.tailscale = {
    enable             = true;
    useRoutingFeatures = "client";
    openFirewall       = true;   # UDP 41641 for the tailscale daemon
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];

  # ── Firewall ──────────────────────────────────────────────────────────────
  # 22 ssh on the LAN — that's the base. Agent container ports are reached over
  # the trusted tailscale0 interface above, so they need no LAN openings here.
  networking.firewall.allowedTCPPorts = [ 22 ];

  # ── IPv6 address-selection fix (same LAN-wide ULA-IPv6 trap as the other
  #    hosts) ──────────────────────────────────────────────────────────────
  # The UniFi LAN hands out ULA IPv6 with no global uplink; glibc prefers IPv6
  # so dual-stacked hosts (image registries, Tailscale coordination) can hang
  # on a dead AAAA. Prefer IPv4 in resolution. Does NOT disable IPv6.
  environment.etc."gai.conf".text = "precedence ::ffff:0:0/96  100\n";

  # ── System packages (admin + container tooling) ──────────────────────────
  environment.systemPackages = with pkgs; [
    vim
    git
    wget
    curl
    htop
    btop
    tmux
    fastfetch
    pciutils             # lspci — was missing on the stock install
    usbutils
    lsof
    file
    tree
    rsync
    bun
    docker-compose       # compose v2 (also shipped as a docker plugin)
    lazydocker           # TUI for containers/logs/stats

    # ── Terminal coding agents (run directly on the host over SSH/Tailscale) ─
    claude-code          # Anthropic Claude Code CLI (unfree — see allowUnfree)
    codex                # OpenAI Codex CLI
    opencode             # OpenCode terminal agent
  ];

  # stateVersion matches the live install on the box (verified 25.11).
  system.stateVersion = "25.11";
}
