{ ... }:

# Declarative /etc/hosts for the LAN fleet. The UniFi gateway only registers
# some DHCP client hostnames in its DNS (e.g. `bastion` resolves, `agentbox`
# does not), so pin them here. Every NixOS host that imports this module can
# then reach the others by name — e.g. `mosh agentbox` from bastion — without
# relying on the gateway or a per-machine hand-edited hosts file.
#
# NOTE: this only fixes resolution ON the NixOS hosts. A non-Nix client (the
# Mac) needs its own /etc/hosts entry, or use Tailscale MagicDNS for fleet-wide
# names including the Mac.
{
  networking.hosts = {
    "192.168.1.10"  = [ "mediaserver" ];
    "192.168.1.79"  = [ "agentbox" ];
    "192.168.1.90"  = [ "bastion" ];
    "192.168.1.251" = [ "homeserver" "aibox" ];
  };
}
