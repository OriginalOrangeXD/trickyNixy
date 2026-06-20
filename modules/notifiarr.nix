{ lib, ... }:

# Notifiarr client (golift/notifiarr) — the Discord / *arr companion daemon.
# No NixOS module or package exists, so it runs as an OCI container exactly like
# Scrypted (Docker + the oci-containers backend are already enabled there; we
# only add a container here).
#
# Outbound-only: the client dials notifiarr.com over a websocket, so there is no
# inbound port to forward and no Caddy vhost is needed. It reaches the box's own
# Sonarr/Radarr/Prowlarr/SABnzbd over the host network at 127.0.0.1.
#
# Config (incl. the account API key) was migrated from the old TrueNAS box into
# /var/lib/notifiarr/notifiarr.conf, with the service-check app blocks re-pointed
# to 127.0.0.1 and the new instance API keys. /etc/machine-id is mounted so the
# client keeps a stable machine identity.
#
# Web UI (LAN): http://192.168.1.10:5454
{
  virtualisation.oci-containers.containers.notifiarr = {
    image = "golift/notifiarr:latest";
    extraOptions = [ "--network=host" ];
    volumes = [
      "/var/lib/notifiarr:/config"
      "/etc/machine-id:/etc/machine-id:ro"
    ];
    autoStart = true;
  };

  networking.firewall.allowedTCPPorts = [ 5454 ];  # Notifiarr web UI (LAN)
}
