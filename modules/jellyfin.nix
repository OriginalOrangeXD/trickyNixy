{ config, lib, pkgs, ... }:

# Jellyfin media server. v1 of the emily-style media stack on this box.
#
# - Runs as `media:media` (defined in modules/media-user.nix) so future *arr
#   services share file ownership without permission gymnastics.
# - Hardware transcoding via NVENC on the RTX 2070 (modules/nvidia.nix wires
#   the driver; the `media` user already gets `video` + `render` groups).
# - LAN-only exposure — no reverse proxy yet. Reach at http://192.168.1.10:8096
# - Library paths point at the migrated ZFS datasets under /srv/media.
#
# Post-deploy bootstrap:
#   1. Open http://192.168.1.10:8096 — Jellyfin setup wizard.
#   2. Add libraries:
#        Movies   → /srv/media/movies
#        TV Shows → /srv/media/tvshows
#        Anime    → /srv/media/anime
#        Music    → /srv/media/music
#        Family   → /srv/media/family
#   3. Settings → Playback → enable Nvidia NVENC (decoders: H.264, HEVC, AV1).
#   4. Settings → Playback → enable Tone mapping for HDR.
#
# Firewall ports opened:
#   8096/tcp  — HTTP web UI + API
#   8920/tcp  — HTTPS (Jellyfin self-signed; unused without a real cert)
#   1900/udp  — DLNA / SSDP discovery (so smart TVs find the server)
#   7359/udp  — Jellyfin client auto-discovery
{
  services.jellyfin = {
    enable       = true;
    user         = "media";
    group        = "media";
    openFirewall = true;
  };

  # `openFirewall = true` opens 8096/tcp + 8920/tcp + 1900/udp + 7359/udp
  # automatically, but be explicit here for documentation. (NixOS deduplicates.)
  networking.firewall = {
    allowedTCPPorts = [ 8096 8920 ];
    allowedUDPPorts = [ 1900 7359 ];
  };

  # /media → /srv/media compatibility symlink. The library was migrated from a
  # TrueNAS Docker Jellyfin that saw its media at /media/{movies,tvshows,...}.
  # Jellyfin derives each item's ID from its file path, and watch history /
  # favorites reference those IDs — so the imported DB must find media at the
  # SAME path strings it was indexed under. This symlink lets the old /media/*
  # paths resolve to the new ZFS location without re-indexing (which would mint
  # new IDs and orphan all watch history).
  systemd.tmpfiles.rules = [
    "L+ /media - - - - /srv/media"
  ];
}
