{ config, lib, pkgs, ... }:

# Deluge torrent client, bound into the wg_client VPN namespace
# (modules/wireguard-netns.nix). All torrent traffic egresses through the
# VPN; if the tunnel drops, the namespace has no route and nothing leaks.
#
# Because deluged lives in the namespace, the host can't reach it directly —
# a socket-activated proxy (deluged-proxy on :58846) joins the namespace and
# bridges the host's Deluge web UI (:8112) to the daemon inside.
#
# Runs as media:media so completed torrents share ownership with the
# /srv/media library that Sonarr/Radarr manage. Hardlink-on-import is wired
# per-dataset — see the tmpfiles block below.
let
  ns = "wg_client";
in
{
  services.deluge = {
    enable = true;
    user   = "media";
    group  = "media";
    web.enable = true;     # web UI on :8112
  };

  # Torrent download dirs. Hardlink-on-import requires the completed file to
  # sit on the SAME ZFS dataset as the destination library — but each media
  # category is its own dataset (bare/media/{movies,tvshows,anime}), separate
  # from bare/media where /srv/media/downloads lives. So completed torrents
  # are moved (via per-label "Move Completed to" in the Deluge Label plugin)
  # into a hidden .downloads dir INSIDE each category's dataset; Sonarr/Radarr
  # then hardlink from there into the library with zero extra space — no
  # double-space-while-seeding. Dot-prefixed so Jellyfin/library scans skip it.
  #   /srv/media/downloads/torrents  — global incomplete/active dir
  #   /srv/media/<category>/.downloads — per-dataset completed + seeding dir
  systemd.tmpfiles.rules = [
    "d /srv/media/downloads           0775 media media -"
    "d /srv/media/downloads/torrents  0775 media media -"
    "d /srv/media/movies/.downloads   0775 media media -"
    "d /srv/media/tvshows/.downloads  0775 media media -"
    "d /srv/media/anime/.downloads    0775 media media -"
  ];

  # Bind the daemon into the VPN namespace.
  systemd.services.deluged = {
    bindsTo  = [ "netns@${ns}.service" ];
    requires = [ "network-online.target" "${ns}.service" ];
    after    = [ "${ns}.service" ];
    serviceConfig.NetworkNamespacePath = [ "/var/run/netns/${ns}" ];
  };

  # Host→namespace bridge so the web UI can talk to deluged.
  systemd.sockets."deluged-proxy" = {
    enable = true;
    description = "Socket for proxy to Deluge daemon in netns";
    listenStreams = [ "58846" ];
    wantedBy = [ "sockets.target" ];
  };
  systemd.services."deluged-proxy" = {
    enable = true;
    description = "Proxy to Deluge daemon in the wg_client namespace";
    requires = [ "deluged.service" "deluged-proxy.socket" ];
    after    = [ "deluged.service" "deluged-proxy.socket" ];
    unitConfig.JoinsNamespaceOf = "deluged.service";
    serviceConfig = {
      User  = config.services.deluge.user;
      Group = config.services.deluge.group;
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:58846";
      PrivateNetwork = "yes";
    };
  };

  networking.firewall.allowedTCPPorts = [ 8112 ];   # Deluge web UI (LAN)
}
