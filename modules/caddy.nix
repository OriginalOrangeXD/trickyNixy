{ config, lib, pkgs, ... }:

# Caddy reverse proxy for the mediaserver. v2 of the media stack.
#
# - Fronts Jellyfin at https://jelly.robby.codes (LAN-only; UniFi serves a
#   split-horizon A record jelly.robby.codes → 192.168.1.10).
# - Real Let's Encrypt certs via DNS-01 challenge against Cloudflare (the
#   box has no public ingress, so HTTP-01 can't work — DNS-01 proves domain
#   ownership by writing a TXT record via the Cloudflare API).
# - The Cloudflare API token is an agenix secret decrypted at boot to
#   /run/agenix/cloudflare-dns-token and fed to Caddy as an EnvironmentFile.
#
# Adding a service later = one more virtualHosts block + a UniFi A record.
let
  # Caddy needs the Cloudflare DNS provider plugin compiled in — the stock
  # binary can't do DNS-01. `withPlugins` builds a custom Caddy on the target.
  # NOTE: `hash` must match the plugin set. On first deploy it will fail with
  # the real hash; paste it in and redeploy. (Standard Nix fixed-output dance.)
  caddyWithCloudflare = pkgs.caddy.withPlugins {
    plugins = [ "github.com/caddy-dns/cloudflare@v0.2.4" ];
    hash = "sha256-J0HWjCPoOoARAxDpG2bS9c0x5Wv4Q23qWZbTjd8nW84=";
  };

  cfTls = ''
    tls {
      dns cloudflare {env.CF_API_TOKEN}
      resolvers 1.1.1.1 8.8.8.8
      propagation_delay 45s
      propagation_timeout -1
    }
  '';
in
{
  # Cloudflare API token, decrypted at boot. Owned by caddy so the unit can
  # read it. File content: `CF_API_TOKEN=<token>` (EnvironmentFile format).
  age.secrets.cloudflare-dns-token = {
    file  = ../secrets/cloudflare-dns-token.age;
    owner = "caddy";
    group = "caddy";
    mode  = "0400";
  };

  services.caddy = {
    enable  = true;
    package = caddyWithCloudflare;
    email   = "deangelis.robert@proton.me";   # ACME expiry notices

    # The local network swallows certmagic's DNS-01 self-check (UniFi
    # split-horizon shadows jelly.robby.codes for the system resolver,
    # and direct UDP/53 to public resolvers doesn't reliably return),
    # so the propagation poll times out even though the TXT record IS
    # created in Cloudflare. Disable the self-check and instead wait a
    # fixed delay, then let Let's Encrypt validate directly — LE queries
    # Cloudflare's authoritative NS, which always has the record.
    virtualHosts."jelly.robby.codes" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:8096
        ${cfTls}
      '';
    };

    # Jellyseerr request front-end. Same DNS-01 tls dance as jelly — UniFi
    # split-horizon serves jellyseerr.robby.codes → 192.168.1.10 on the LAN.
    virtualHosts."jellyseerr.robby.codes" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:5055
        ${cfTls}
      '';
    };

    # req.robby.codes is the request front-end's canonical/legacy hostname.
    virtualHosts."req.robby.codes" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:5055
        ${cfTls}
      '';
    };

    # Vaultwarden password manager (migrated from TrueNAS). Reverse_proxy also
    # carries the /notifications/hub websocket automatically.
    virtualHosts."vault.robby.codes" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:8222
        ${cfTls}
      '';
    };

    # Immich photo management (migrated from TrueNAS, runs as OCI containers).
    virtualHosts."immich.robby.codes" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:2283
        ${cfTls}
      '';
    };

    # GitLab CE (migrated from TrueNAS, omnibus container on HTTP :80 -> 8929).
    virtualHosts."gitlab.robby.codes" = {
      extraConfig = ''
        reverse_proxy 127.0.0.1:8929
        ${cfTls}
      '';
    };
  };

  # Feed the Cloudflare token to Caddy's process environment.
  systemd.services.caddy.serviceConfig.EnvironmentFile =
    config.age.secrets.cloudflare-dns-token.path;

  # Caddy needs 80 (ACME/redirects) + 443 (HTTPS).
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
