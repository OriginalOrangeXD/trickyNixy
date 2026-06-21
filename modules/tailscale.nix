{ config, lib, ... }:

# Tailscale — put every box on the tailnet (tail6a5c4f.ts.net) so they're
# reachable by a stable MagicDNS name from anywhere, independent of LAN IPs.
# (Dead LAN IPs proved fragile — they silently loopback'd through the Mac's
# ssh config and masked decommissioned hosts. Tailnet names don't lie.)
#
# Declarative join: services.tailscale.authKeyFile points at an agenix-encrypted
# reusable pre-auth key (secrets/tailscale-authkey.age), so a host auto-joins on
# first deploy — no manual `sudo tailscale up`. The key is only consulted at
# join time; once a box is on the tailnet it stays, even after the key expires.
# Rotate: regenerate at https://login.tailscale.com/admin/settings/keys and
# re-encrypt secrets/tailscale-authkey.age.
{
  # Reusable pre-auth key, decrypted at activation (root-only). Read by the
  # tailscaled-autoconnect service to bring the box onto the tailnet.
  age.secrets.tailscale-authkey.file = ../secrets/tailscale-authkey.age;

  services.tailscale = {
    enable             = true;
    # mkDefault so a host can promote itself to a subnet router ("both").
    useRoutingFeatures = lib.mkDefault "client";
    openFirewall       = true;   # UDP 41641 for the tailscale daemon
    authKeyFile        = config.age.secrets.tailscale-authkey.path;
  };

  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
