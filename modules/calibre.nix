{ lib, ... }:

# Calibre-Web-Automated (CWA) — the book library + reader UI + OPDS feed that
# KOReader pulls books from. No nixpkgs module; the blessed deployment is the
# crocodilestick/calibre-web-automated container, run here as an OCI container
# on Docker (the backend is already enabled in modules/scrypted.nix), exactly
# like notifiarr/immich.
#
# CWA watches an INGEST folder and auto-imports anything dropped there into the
# Calibre library (metadata fix, cover fetch, optional format convert), then
# serves the result over OPDS. The book *acquisition* half — searching Anna's
# Archive and dropping files into that ingest folder — is
# modules/book-downloader.nix, which runs inside the Mullvad VPN namespace.
# CWA itself makes no shadow-library calls, so it stays on the LAN.
#
# Page-sync (reading position across devices) is NOT CWA's job — that is a
# separate protocol, modules/kosync.nix.
#
# Storage (books are their own ZFS dataset, like movies/tvshows/anime —
# create bare/media/books and mount at /srv/media/books per the runbook;
# tmpfiles only guarantees the dirs/ownership, it does not make the dataset):
#   /srv/media/books          Calibre library (CWA-managed)  -> /calibre-library
#   /srv/media/books/.ingest  watch folder. Dot-prefixed so Jellyfin/library
#                             scans skip it — same convention as deluge's
#                             per-dataset .downloads dirs.            -> /cwa-book-ingest
#   /var/lib/cwa              CWA app config + internal db            -> /config
#
# Web UI + OPDS (LAN): http://192.168.1.10:8083   (OPDS at …/opds)
# First-boot login is the upstream default admin / admin123 — change it
# immediately; this box has no WAN exposure but the LAN default is still weak.
{
  systemd.tmpfiles.rules = [
    "d /srv/media/books         0775 media media -"
    "d /srv/media/books/.ingest 0775 media media -"
    "d /var/lib/cwa             0775 media media -"
  ];

  virtualisation.oci-containers.containers.calibre-web-automated = {
    image = "ghcr.io/crocodilestick/calibre-web-automated:latest";
    environment = {
      PUID = "10000";          # media
      PGID = "10000";          # media
      TZ   = "America/Toronto";
    };
    volumes = [
      "/var/lib/cwa:/config"
      "/srv/media/books:/calibre-library"
      "/srv/media/books/.ingest:/cwa-book-ingest"
    ];
    ports     = [ "8083:8083" ];
    autoStart = true;
  };

  networking.firewall.allowedTCPPorts = [ 8083 ];   # CWA web UI + OPDS (LAN)
}
