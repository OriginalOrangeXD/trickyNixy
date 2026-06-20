{
  description = "Declarative homeserver deployment — llama.cpp (kappa CPU + Qwen3-VL GPU) for the UniFi/HA video-analysis stack";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Jovian-NixOS — the SteamOS (gamescope / Deck UI) layer for the gaming box.
    # Its `master` branch tracks nixos-unstable, so it follows our nixpkgs.
    jovian = {
      url = "github:Jovian-Experiments/Jovian-NixOS";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, agenix, ... }@inputs:
    let
      hostSystem = "x86_64-linux";   # change to aarch64-linux if your box is ARM
      editorSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllEditors = nixpkgs.lib.genAttrs editorSystems;
    in {

      # ── NixOS host config ("compute" box) at 192.168.1.251. Deploy with:
      #    nixos-rebuild switch \
      #      --flake .#homeserver \
      #      --target-host robby@192.168.1.251 \
      #      --build-host  robby@192.168.1.251 \
      #      --use-remote-sudo
      nixosConfigurations.homeserver = nixpkgs.lib.nixosSystem {
        system = hostSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/homeserver/configuration.nix
          ./modules/gpu.nix
          ./modules/vlm.nix
          ./modules/fan-control.nix
          agenix.nixosModules.default
        ];
      };

      # ── Media server at 192.168.1.10. Base foundation only — storage,
      #    TrueNAS migration, and media services land in later modules.
      #    Deploy with:
      #      nixos-rebuild switch \
      #        --flake .#mediaserver \
      #        --target-host robby@192.168.1.10 \
      #        --build-host  robby@192.168.1.10 \
      #        --use-remote-sudo \
      #        --ask-sudo-password    # first deploy only
      nixosConfigurations.mediaserver = nixpkgs.lib.nixosSystem {
        system = hostSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/mediaserver/configuration.nix
          ./modules/zfs.nix
          ./modules/nvidia.nix
          ./modules/media-user.nix
          ./modules/jellyfin.nix
          ./modules/caddy.nix
          ./modules/cloudflared.nix
          ./modules/wireguard-netns.nix
          ./modules/deluge.nix
          ./modules/sabnzbd.nix
          ./modules/arr.nix
          ./modules/bazarr.nix
          ./modules/jellyseerr.nix
          ./modules/flaresolverr.nix
          ./modules/scrypted.nix
          ./modules/notifiarr.nix
          ./modules/vaultwarden.nix
          ./modules/immich.nix
          ./modules/gitlab.nix
          ./modules/calibre.nix
          ./modules/book-downloader.nix
          ./modules/kosync.nix
          agenix.nixosModules.default
        ];
      };

      # ── Agent box at 192.168.1.79 — Docker host for self-hosted agents
      #    (formerly `gamebox`, an AMD RX 5700 SteamOS console). Plain Docker
      #    engine; containers run by hand via `docker compose`, not declared in
      #    Nix. Reached over Tailscale (kept from the gaming build); no LAN
      #    port-forwarding. Deploy with:
      #      nixos-rebuild switch \
      #        --flake .#agentbox \
      #        --target-host robby@192.168.1.79 \
      #        --build-host  robby@192.168.1.79 \
      #        --use-remote-sudo
      nixosConfigurations.agentbox = nixpkgs.lib.nixosSystem {
        system = hostSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/agentbox/configuration.nix
          ./modules/lan-hosts.nix
          agenix.nixosModules.default
        ];
      };

      # ── aibox at 192.168.1.251 (same box as `homeserver` — pick the flake
      #    entry you want for the current role). aibox runs an X11 + Steam-
      #    Big-Picture stack on the RTX 3080 Ti to reproduce-or-rule-out
      #    the DualSense flicker we hit on Navi10. We do NOT pull in Jovian/
      #    gamescope here: NVIDIA + gamescope KMS atomic is broken in ways
      #    we couldn't unblock (libliftoff floods drmModeAtomicCommit even
      #    with open module + WLR_DRM_NO_ATOMIC + --disable-layers). X11 +
      #    Sunshine streams cleanly on NVIDIA. Deploy with:
      #      nixos-rebuild switch \
      #        --flake .#aibox \
      #        --target-host robby@192.168.1.251 \
      #        --build-host  robby@192.168.1.251 \
      #        --sudo
      #    Reverting to AI inference is one redeploy of `.#homeserver`.
      nixosConfigurations.aibox = nixpkgs.lib.nixosSystem {
        system = hostSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/aibox/configuration.nix
          ./modules/sunshine.nix
          ./modules/nvidia.nix
          agenix.nixosModules.default
        ];
      };

      # ── bastion at 192.168.1.90 — terminal-only SSH jump host / admin
      #    laptop. No GUI; the box exists to reach OTHER machines and rarely
      #    runs anything itself. Colemak console keymap + Terminus TTY font;
      #    lid-close is ignored so it stays reachable shut. Deploy with:
      #      nixos-rebuild switch \
      #        --flake .#bastion \
      #        --target-host robby@192.168.1.90 \
      #        --build-host  robby@192.168.1.90 \
      #        --use-remote-sudo
      nixosConfigurations.bastion = nixpkgs.lib.nixosSystem {
        system = hostSystem;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/bastion/configuration.nix
          ./modules/lan-hosts.nix
          agenix.nixosModules.default
        ];
      };

      # ── Convenience: agenix CLI in `nix run .#agenix` for editing secrets.
      #    Exposed for every system you might edit secrets from.
      packages = forAllEditors (system: {
        agenix = agenix.packages.${system}.default;
      });
    };
}
