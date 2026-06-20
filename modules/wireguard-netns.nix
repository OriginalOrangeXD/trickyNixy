{ config, lib, pkgs, ... }:

# WireGuard VPN killswitch via a network namespace (adapted from notthebee's
# nix-config). The `wg_client` namespace's ONLY route is the WireGuard wg0
# interface — any service bound into this namespace can reach the internet
# exclusively through the VPN. If the tunnel drops, the namespace has no
# route and traffic simply stops (killswitch by construction, no leak).
#
# The torrent daemon (modules/deluge.nix) binds into this namespace.
#
# The wg config (private key + peer) lives in agenix (secrets/wg-client.age)
# in `wg setconf` format. The interface Address + DNS are NOT in that file —
# they're the non-secret values below (VPN-assigned internal IPs).
let
  namespace = "wg_client";

  # ── From the Mullvad WireGuard config ───────────────────────────────────
  # Dual-stack: both the IPv4 and IPv6 tunnel addresses are assigned to wg0.
  # dnsIP is Mullvad's in-tunnel resolver (reachable only through the tunnel).
  privateIPs = [
    "10.65.103.163/32"
    "fc00:bbbb:bbbb:bb01::2:67a2/128"
  ];
  dnsIP = "10.64.0.1";
in
{
  age.secrets.wg-client = {
    file  = ../secrets/wg-client.age;
    owner = "root";
    group = "root";
    mode  = "0400";
  };

  # `wg` on PATH for checking tunnel status:
  #   sudo ip netns exec wg_client wg show
  environment.systemPackages = [ pkgs.wireguard-tools ];

  # The namespace gets its own resolv.conf so services inside resolve via the
  # VPN's DNS, not the host's (prevents DNS leaks outside the tunnel).
  environment.etc."netns/${namespace}/resolv.conf".text = "nameserver ${dnsIP}";

  # Generic "create a network namespace named %I" template unit.
  systemd.services."netns@" = {
    description = "%I network namespace";
    before = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.iproute2}/bin/ip netns add %I";
      ExecStop  = "${pkgs.iproute2}/bin/ip netns del %I";
    };
  };

  # Bring up wg0 INSIDE the namespace and make it the default route.
  systemd.services.${namespace} = {
    description = "${namespace} WireGuard interface";
    bindsTo  = [ "netns@${namespace}.service" ];
    requires = [ "network-online.target" ];
    after    = [ "netns@${namespace}.service" "network-online.target" ];
    wants    = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writers.writeBash "wg-up" ''
        set -e
        # Idempotent: clear any wg0 left behind by a failed prior start
        # (oneshot ExecStop doesn't run if ExecStart failed partway).
        ${pkgs.iproute2}/bin/ip -n ${namespace} link del wg0 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link del wg0 2>/dev/null || true
        ${pkgs.iproute2}/bin/ip link add wg0 type wireguard
        ${pkgs.iproute2}/bin/ip link set wg0 netns ${namespace}
        ${lib.concatMapStringsSep "\n        " (ip:
          "${pkgs.iproute2}/bin/ip -n ${namespace} address add ${ip} dev wg0") privateIPs}
        # `wg setconf` only accepts plain WireGuard format — strip the
        # wg-quick-only lines (Address/DNS/MTU) so a pasted provider config
        # works as-is. Address is applied above; DNS via the netns resolv.conf.
        ${pkgs.iproute2}/bin/ip netns exec ${namespace} \
          ${pkgs.wireguard-tools}/bin/wg setconf wg0 \
          <(${pkgs.gnugrep}/bin/grep -vE '^(Address|DNS|MTU)' ${config.age.secrets.wg-client.path})
        ${pkgs.iproute2}/bin/ip -n ${namespace} link set wg0 up
        ${pkgs.iproute2}/bin/ip -n ${namespace} link set lo up
        ${pkgs.iproute2}/bin/ip -n ${namespace} route add default dev wg0
        # IPv6 default via wg0 too. Mullvad's peer AllowedIPs is 0.0.0.0/0
        # (IPv4 only), so WireGuard drops any IPv6 here rather than leaking it —
        # and the netns has no other interface anyway. Best-effort.
        ${pkgs.iproute2}/bin/ip -n ${namespace} -6 route add default dev wg0 || true
      '';
      ExecStop = pkgs.writers.writeBash "wg-down" ''
        ${pkgs.iproute2}/bin/ip -n ${namespace} route del default dev wg0 || true
        ${pkgs.iproute2}/bin/ip -n ${namespace} link del wg0 || true
      '';
    };
  };
}
