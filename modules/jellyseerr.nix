{ config, lib, ... }:

# Jellyseerr — media request & discovery front-end for the stack. Users browse,
# search, and request movies/TV; approved requests are handed to Sonarr/Radarr,
# and "available" status is synced back from Jellyfin. v3 of the media stack —
# the layer that turns the *arr automation into something other people can use.
#
# Runs as its own DynamicUser (state in /var/lib/jellyseerr). It talks to
# Jellyfin/Sonarr/Radarr over HTTP on localhost and never touches /srv/media, so
# — unlike jellyfin/bazarr/*arr — it is deliberately NOT in the media group.
#
# Fronted by Caddy at https://jellyseerr.robby.codes (see caddy.nix). Port 5055
# is also opened on the LAN for the first-run setup wizard and direct access.
#
# After deploy, finish setup at http://192.168.1.10:5055 (or the https host):
#   1. Sign in with Jellyfin → server http://localhost:8096, your admin creds.
#   2. Settings → Services → Radarr → localhost:7878 + API key; default root
#      folder /srv/media/movies, pick the default quality profile.
#   3. Settings → Services → Sonarr → localhost:8989 + API key; default root
#      folder /srv/media/tvshows.
#      ANIME GOTCHA: Jellyseerr applies one default Sonarr profile per server.
#      To keep the "always Japanese audio" policy, add a SECOND Sonarr service
#      entry (same host) pinned to the "Anime" quality profile (id 7) and route
#      anime requests to it — otherwise requested anime lands on the default
#      profile and may grab English dubs. See mediaserver-buildout memory.
{
  services.jellyseerr = {
    enable       = true;
    port         = 5055;
    openFirewall = true;   # LAN-direct access + first-run setup wizard
  };
}
