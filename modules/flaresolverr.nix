{ config, lib, pkgs, ... }:

# FlareSolverr — a headless-Chromium proxy that solves Cloudflare's
# "checking your browser" challenge so Prowlarr can query trackers that sit
# behind it (1337x, TorrentGalaxy, …). Prowlarr routes those indexers through
# it via an Indexer Proxy (Settings → Indexers → add FlareSolverr, host
# http://localhost:8191, tag "flaresolverr", then add that tag to each
# Cloudflare-protected indexer).
#
# Listens on :8191. The firewall is NOT opened for it — Prowlarr runs on the
# same host and reaches it over localhost, so there's no reason to expose it
# on the LAN.
#
# Network note: FlareSolverr and Prowlarr both run on the HOST network, not
# the wg_client VPN namespace. Indexer *queries* therefore egress over the
# box's normal ISP route; only deluged's torrent traffic goes through Mullvad.
# That's the same split notthebee's config uses — only the torrent client is
# in the killswitch namespace.
{
  services.flaresolverr.enable = true;   # :8191, localhost-reachable
}
