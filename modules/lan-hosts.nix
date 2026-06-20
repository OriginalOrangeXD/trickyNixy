{ ... }:

# Declarative /etc/hosts for the LAN fleet. The UniFi gateway doesn't register
# every DHCP client hostname in its DNS (e.g. `agentbox` does not resolve), so
# pin them here. Every NixOS host that imports this module can then reach the
# others by name — e.g. `mosh mediaserver` from agentbox — without relying on
# the gateway or a per-machine hand-edited hosts file.
#
# NOTE: this only fixes resolution ON the NixOS hosts. A non-Nix client (the
# Mac) needs its own /etc/hosts entry, or use Tailscale MagicDNS for fleet-wide
# names including the Mac.
{
  networking.hosts = {
    "192.168.1.10"  = [ "mediaserver" ];
    "192.168.1.79"  = [ "agentbox" ];
  };
}
