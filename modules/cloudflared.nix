{ config, lib, pkgs, ... }:

# Cloudflare Tunnel connector for remote access to Jellyfin (and future
# services). v2.5 of the media stack.
#
# Replaces the dead TrueNAS cloudflared tunnels. Outbound-only — cloudflared
# dials Cloudflare's edge, so there's no inbound port to forward and NAT is a
# non-issue.
#
# Topology:
#   At home : UniFi DNS → 192.168.1.10 → Caddy (LE cert) → Jellyfin :8096
#   Remote  : Cloudflare edge (CF cert) → this tunnel → http://localhost:8096
#
# This is a "remotely-managed" (token-based) tunnel: the ingress / public
# hostname routes are configured in the Cloudflare Zero Trust dashboard, and
# this connector just runs with the tunnel token. cloudflared reads the token
# from the TUNNEL_TOKEN env var, supplied via the agenix EnvironmentFile.
#
# Dashboard config (Zero Trust → Networks → Tunnels → <tunnel> → Public
# Hostnames): jelly.robby.codes → HTTP → localhost:8096
{
  # Tunnel connector token, decrypted at boot. Read by systemd (as root)
  # before the service drops privileges, so the unit user never touches it.
  age.secrets.cloudflared-token = {
    file  = ../secrets/cloudflared-token.age;
    owner = "root";
    group = "root";
    mode  = "0400";
  };

  systemd.services.cloudflared-tunnel = {
    description = "Cloudflare Tunnel (remote access)";
    after       = [ "network-online.target" ];
    wants       = [ "network-online.target" ];
    wantedBy    = [ "multi-user.target" ];

    serviceConfig = {
      # TUNNEL_TOKEN=<token> — systemd reads this as root and injects it.
      EnvironmentFile = config.age.secrets.cloudflared-token.path;
      ExecStart = "${pkgs.cloudflared}/bin/cloudflared tunnel --no-autoupdate --metrics 127.0.0.1:36500 run";
      Restart    = "always";
      RestartSec = "5s";
      # Isolated, unprivileged runtime user (systemd reads the token file
      # before dropping to this user, so DynamicUser is fine here).
      DynamicUser        = true;
      NoNewPrivileges    = true;
      ProtectSystem      = "strict";
      ProtectHome        = true;
      PrivateTmp         = true;
    };
  };
}
