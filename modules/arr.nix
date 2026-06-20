{ config, lib, ... }:

# The *arr automation core: Prowlarr (indexer manager) + Sonarr (TV) +
# Radarr (movies). Sonarr/Radarr run as media:media so they can hardlink
# completed downloads from /srv/media/downloads into /srv/media/{tvshows,
# movies}. Prowlarr touches no media files (it only feeds indexers to the
# others via API), so it runs as its own service user.
#
# LAN-only — reach each on its port from home:
#   Prowlarr :9696 · Sonarr :8989 · Radarr :7878
{
  services.prowlarr.enable = true;          # :9696

  services.sonarr = {
    enable = true;                          # :8989
    user   = "media";
    group  = "media";
  };

  services.radarr = {
    enable = true;                          # :7878
    user   = "media";
    group  = "media";
  };

  # Recycle bin for Sonarr/Radarr deletions — files they delete or replace are
  # moved here for 30 days (set via each app's mediamanagement config) instead
  # of being permanently removed. Added after an import permanently wiped data
  # that a recycle bin would have caught.
  systemd.tmpfiles.rules = [
    "d /srv/media/.recycle        0775 media media -"
    "d /srv/media/.recycle/sonarr 0775 media media -"
    "d /srv/media/.recycle/radarr 0775 media media -"
  ];

  networking.firewall.allowedTCPPorts = [ 9696 8989 7878 ];
}
