{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/mosh.nix
  ];

  # ── Nix settings ────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # CUDA binary cache substituters live in modules/gpu.nix.

  # ── Identity ────────────────────────────────────────────────────────────
  networking.hostName = "nixos";
  networking.useDHCP  = lib.mkDefault true;

  time.timeZone     = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  services.xserver.xkb = {
    layout  = "us";
    variant = "";
  };

  # ── Bootloader ──────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Deploy user (target of `nixos-rebuild --target-host robby@…`) ────────
  users.users.robby = {
    isNormalUser = true;
    description  = "Robert (deploy / admin)";
    extraGroups  = [ "wheel" "networkmanager" "docker" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG7WQgXfplk8FlV5CgyKxHaLRpTMtJcyct3s6ADdOYJ9 robby@Roberts-MacBook-Pro.local"
    ];
  };

  # Passwordless sudo for the `wheel` group makes --sudo / --use-remote-sudo seamless.
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
  # 22   ssh
  # 8000 llama.cpp (kappa, CPU-only per D-16/Shape 4) OpenAI-compatible endpoint
  # 8001 llama.cpp (Qwen3-VL on GPU) OpenAI-compatible endpoint — consumed by
  #      ha-llmvision running on the HA host (192.168.1.16)
  # 8123 Home Assistant (only if HA runs on this box; safe to leave open)
  networking.firewall.allowedTCPPorts = [ 22 8000 8001 8123 ];

  # ── System packages (parity with canonical /home/robby/flake) ───────────
  environment.systemPackages = with pkgs; [
    vim
    neovim
    git
    wget
    bun
    fastfetch
    opencode
    nvtopPackages.full   # GPU monitor — sees both NVIDIA and AMD
    pciutils             # `lspci`
  ];

  # ── llama.cpp serving kappa on port 8000 (CPU-only) ─────────────────────
  # Per D-16 (Shape 4): kappa is demoted to CPU-only (-ngl 0) so the 12 GB
  # 3080 Ti is dedicated to the VLM (Qwen3-VL on :8001 via modules/vlm.nix).
  # --cpu-moe is no longer meaningful since everything is on CPU. kappa loses
  # ~15-30% throughput; VLM stays warm for camera-event "describe the door"
  # calls from ha-llmvision.
  services.llama-cpp = {
    enable      = true;
    package     = pkgs.llama-cpp.override { cudaSupport = true; };
    model       = "/var/lib/llama/models/kappa-20b-131k.MXFP4_MOE.gguf";
    host        = "0.0.0.0";
    port        = 8000;
    openFirewall = true;
    extraFlags = [
      "-ngl" "0"              # CPU-only — Shape 4: VLM owns the GPU
      "-c" "65536"            # 64k context
      "--cache-type-k" "q8_0"
      "--cache-type-v" "q8_0"
      "--flash-attn" "on"
      "-np" "2"               # 2 parallel slots
      "--jinja"               # use embedded chat template (handles tool calling)
    ];
  };

  # ── llama.cpp VLM (Qwen3-VL 8B) on port 8001 (GPU) ──────────────────────
  # Per D-16: dedicates the 3080 Ti to the VLM. Consumed by ha-llmvision on
  # the HA host (192.168.1.16) for per-camera "describe + threat-score"
  # automations. Defaults in modules/vlm.nix: Q4_K_M GGUF, 32K context,
  # -ngl 999, single parallel slot.
  services.llama-cpp-vlm = {
    enable = true;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/llama         0755 robby users -"
    "d /var/lib/llama/models  0755 robby users -"
  ];

  # ── agenix: HA bearer token ─────────────────────────────────────────────
  # Per D-16: KEPT after Turnstone removal. Decrypted at boot to
  # /run/agenix/ha-token. No service on this box reads it today — repurposed
  # as the canonical store for the HA Long-Lived Access Token used by
  # ha-llmvision (on the HA host) and the PAI Skill (on Robert's laptop).
  # Re-rotate: `nix run .#agenix -- -e secrets/ha-token.age`.
  age.secrets.ha-token = {
    file  = ../../secrets/ha-token.age;
    owner = "robby";
    group = "users";
    mode  = "0400";
  };

  # ── (REMOVED) Turnstone service ─────────────────────────────────────────
  # Per D-16: PAI-only skill surface chosen. Turnstone (modules/turnstone.nix
  # + pkgs/turnstone.nix) deleted from the flake. Camera Q+A flows through
  # ha-llmvision (on HA) and the PAI Skill on Robert's laptop, not Turnstone.

  # ── (REMOVED) Home Assistant local-host option block ────────────────────
  # HA continues to run on the dedicated host at 192.168.1.16, not here.

  # stateVersion matches the install on the box (canonical = 25.11).
  system.stateVersion = "25.11";
}
