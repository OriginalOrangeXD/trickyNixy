{ config, lib, ... }:

# Bazarr — subtitle companion to Sonarr/Radarr. It watches their libraries
# and downloads subtitles from providers (OpenSubtitles, etc.), keeping every
# episode/movie subbed. Added after an in-place Sonarr import wiped One Piece's
# ~900 sidecar .srt files: Bazarr re-fetches subs for the whole library and
# keeps future imports covered.
#
# Runs as media:media so it writes .srt files alongside videos in /srv/media.
# After deploy, wire it up in its UI (http://192.168.1.10:6767):
#   Settings → Sonarr  → host localhost, port 8989, Sonarr's API key
#   Settings → Radarr  → host localhost, port 7878, Radarr's API key
#   Settings → Providers → add OpenSubtitles (needs your account)
# then Series → One Piece → search subtitles to backfill.
{
  services.bazarr = {
    enable     = true;
    user       = "media";
    group      = "media";
    listenPort = 6767;
  };

  networking.firewall.allowedTCPPorts = [ 6767 ];   # Bazarr web UI (LAN)
}
