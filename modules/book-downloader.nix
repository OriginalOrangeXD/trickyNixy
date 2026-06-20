{ config, lib, pkgs, ... }:

# CWA-Book-Downloader — the search-and-click acquisition front end. A small
# Flask web UI: you search a title, it fetches the file over HTTPS from Anna's
# Archive and drops it into CWA's ingest folder (modules/calibre.nix), which
# auto-imports it ~minutes later. This is the ONLY service that talks to
# shadow-library servers, so it is the ONLY one bound into the Mullvad VPN
# namespace.
#
# ── Why this one is different from CWA/kosync ────────────────────────────────
# The wg_client netns (modules/wireguard-netns.nix) is a WireGuard killswitch:
# its only route is the Mullvad tunnel, so anything inside it reaches the
# internet exclusively through the VPN and leaks nothing if the tunnel drops.
# deluged binds in via systemd's NetworkNamespacePath. This container can't do
# that — Docker can't join a host-created netns — so it runs under *podman*,
# which CAN attach to an existing named netns with `--network ns:`. That single
# difference is why this is a raw podman systemd unit instead of an
# oci-containers entry like CWA. (Docker stays the backend for everything else.)
#
#   container egress   -> 127.0.0.1 inside wg_client -> wg0 -> Mullvad
#   --dns 10.64.0.1    -> Mullvad's in-tunnel resolver (no DNS leak; same IP
#                         the netns resolv.conf uses)
#   ingest file write  -> /srv/media/books/.ingest. A netns isolates NETWORK
#                         only, not the filesystem — so the LAN-side CWA still
#                         sees the dropped file and imports it. The VPN boundary
#                         and the file handoff are orthogonal.
#
# The web UI lives inside the namespace, so the host can't reach it directly —
# a socket-activated proxy (book-downloader-proxy) bridges the host LAN port to
# the container, exactly like modules/deluge.nix's deluged-proxy bridges the
# Deluge daemon.
#
# FlareSolverr (Cloudflare bypass) is intentionally NOT wired yet: the existing
# instance (modules/flaresolverr.nix) sits on the host network, unreachable from
# inside the netns. Direct file fetches usually don't need it; add a
# netns-reachable solver later only if Anna's search starts failing.
#
# Web UI (LAN): http://192.168.1.10:8084
let
  ns        = "wg_client";
  netnsPath = "/var/run/netns/${ns}";
  port      = 8084;            # CWA-Book-Downloader's default Flask port
  image     = "ghcr.io/calibrain/calibre-web-automated-book-downloader:latest";
in
{
  # Podman alongside the existing Docker backend, just for this one container
  # (the only thing that needs to join the host netns).
  virtualisation.podman.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/book-downloader 0775 media media -"
  ];

  # The downloader container, attached to the existing Mullvad killswitch netns.
  # bindsTo wg_client so it dies with the tunnel; podman --network ns: makes it
  # share that namespace's (VPN-only) network stack.
  systemd.services.book-downloader = {
    description = "CWA-Book-Downloader (inside ${ns} VPN namespace)";
    bindsTo  = [ "netns@${ns}.service" "${ns}.service" ];
    requires = [ "network-online.target" "${ns}.service" ];
    after    = [ "${ns}.service" "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    path     = [ pkgs.podman ];
    serviceConfig = {
      Type = "simple";
      # --replace clears any container left by a hard restart; --rm on exit.
      ExecStart = lib.concatStringsSep " \\\n        " [
        "${pkgs.podman}/bin/podman run --rm --replace --name book-downloader"
        "--network ns:${netnsPath}"          # join the Mullvad killswitch netns
        "--dns 10.64.0.1"                     # Mullvad in-tunnel resolver
        # Do NOT pass --user: the shelfmark entrypoint must start as root to
        # set up /tmp/shelfmark, then drops to PUID/PGID itself (and chowns
        # ingest output to them) so imported files land as media:media. Forcing
        # --user trips the non-root branch -> "/tmp/shelfmark not writable".
        "-e PUID=10000 -e PGID=10000"         # -> media:media at runtime
        "-e INGEST_DIR=/cwa-book-ingest"
        "-e TZ=America/Toronto"
        "-v /srv/media/books/.ingest:/cwa-book-ingest"
        "-v /var/lib/book-downloader:/config"
        image
      ];
      ExecStop = "${pkgs.podman}/bin/podman stop book-downloader";
      Restart  = "on-failure";
    };
  };

  # Host→namespace bridge so the LAN can reach the in-netns web UI, mirroring
  # deluged-proxy. The .socket is created by systemd in the HOST net namespace
  # (it has no NetworkNamespacePath), so it listens on the LAN; the .service
  # joins wg_client and forwards the accepted connection to the container on
  # 127.0.0.1:${port} inside the tunnel namespace.
  systemd.sockets.book-downloader-proxy = {
    description   = "Socket for proxy to book-downloader in netns";
    listenStreams = [ "${toString port}" ];
    wantedBy      = [ "sockets.target" ];
  };
  systemd.services.book-downloader-proxy = {
    description = "Proxy to book-downloader in the ${ns} namespace";
    requires = [ "book-downloader.service" "book-downloader-proxy.socket" ];
    after    = [ "book-downloader.service" "book-downloader-proxy.socket" ];
    serviceConfig = {
      NetworkNamespacePath = [ netnsPath ];
      ExecStart = "${pkgs.systemd}/lib/systemd/systemd-socket-proxyd --exit-idle-time=5min 127.0.0.1:${toString port}";
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];   # downloader web UI (LAN)
}
