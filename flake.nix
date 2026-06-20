{
  description = "Declarative NixOS deployment — mediaserver (media stack) + agentbox (self-hosted agents / PAI)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Jovian-NixOS — the SteamOS (gamescope / Deck UI) layer for the gaming box.
    # Its `master` branch tracks nixos-unstable, so it follows our nixpkgs.
    # NOTE: currently unreferenced — the gaming/aibox host was decommissioned.
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

      # ── Media server at 192.168.1.10 — storage + media stack. Deploy with:
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

      # ── Agent box at 192.168.1.79 — Docker host for self-hosted agents +
      #    the PAI instance. Plain Docker engine; containers run by hand via
      #    `docker compose`, not declared in Nix. Reached over Tailscale; no
      #    LAN port-forwarding. Deploy with:
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

      # ── Convenience: agenix CLI in `nix run .#agenix` for editing secrets.
      #    Exposed for every system you might edit secrets from.
      packages = forAllEditors (system: {
        agenix = agenix.packages.${system}.default;
      });
    };
}
