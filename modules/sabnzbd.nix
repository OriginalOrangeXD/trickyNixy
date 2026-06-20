{ config, lib, ... }:

# SABnzbd usenet downloader. Runs on the HOST network (not the VPN namespace)
# — usenet is a private, paid SSL connection to your provider with no peer
# exposure, so it doesn't need the torrent killswitch. Runs as media:media so
# completed downloads hardlink into the /srv/media library.
{
  services.sabnzbd = {
    enable = true;
    user   = "media";
    group  = "media";
  };

  systemd.tmpfiles.rules = [
    "d /srv/media/downloads/usenet 0775 media media -"
  ];

  networking.firewall.allowedTCPPorts = [ 8080 ];   # SABnzbd web UI (LAN)
}
