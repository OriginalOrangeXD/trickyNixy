{ lib, ... }:

# kosync — KOReader's progress-sync server (reading position across devices).
# SEPARATE system from Calibre/OPDS: Calibre moves books, kosync syncs your
# page. KOReader's "Progress sync" plugin points at this server and pushes the
# current location after each chapter; the other device pulls it on open.
#
# Self-hosted (vs KOReader's public sync.koreader.rocks) so reading positions
# never leave the box. LAN-only, no external egress, no VPN — runs as an OCI
# container on Docker like the others.
#
# Image is a self-contained single-container implementation
# (b1n4ryj4n/koreader-sync): no Redis — unlike the official
# koreader/koreader-sync-server, which is OpenResty + Redis and would need a
# redis sidecar like immich's. Listens on 8081, persists to /app/data.
#
# OPEN_REGISTRATIONS=True lets KOReader create the account on first connect;
# flip it to False once both devices are enrolled to lock the server down.
#
# Storage:  /var/lib/kosync  ->  /app/data   (user + progress store)
# Endpoint (LAN): http://192.168.1.10:8081
#
# KOReader setup (BOTH devices): Tools → Progress sync → Custom sync server →
#   http://192.168.1.10:8081  then Register (first device) / Login (second).
{
  systemd.tmpfiles.rules = [
    "d /var/lib/kosync 0775 media media -"
  ];

  virtualisation.oci-containers.containers.kosync = {
    image = "b1n4ryj4n/koreader-sync:latest";
    environment = {
      OPEN_REGISTRATIONS       = "True";    # let KOReader register; flip False after enrolling
      RECEIVE_RANDOM_DEVICE_ID = "False";
    };
    volumes   = [ "/var/lib/kosync:/app/data" ];
    ports     = [ "8081:8081" ];
    autoStart = true;
  };

  networking.firewall.allowedTCPPorts = [ 8081 ];   # kosync (LAN)
}
