{ lib, ... }:

# Tailscale — put every box on the tailnet (tail6a5c4f.ts.net) so they're
# reachable by a stable MagicDNS name from anywhere, independent of LAN IPs.
# (Dead LAN IPs proved fragile — they silently loopback'd through the Mac's
# ssh config and masked decommissioned hosts. Tailnet names don't lie.)
#
# This module ENABLES the daemon, opens its UDP/41641 port, and trusts the
# tailscale0 interface so tailnet-reachable services need no per-port LAN
# firewall openings. Joining the tailnet is a one-time auth per box:
#
#     sudo tailscale up
#
# (opens a login URL). For a fully hands-off / reproducible join, set
# services.tailscale.authKeyFile to an agenix-encrypted pre-auth key generated
# at https://login.tailscale.com/admin/settings/keys instead.
{
  services.tailscale = {
    enable             = true;
    useRoutingFeatures = "client";
    openFirewall       = true;   # UDP 41641 for the tailscale daemon
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
