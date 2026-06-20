{ config, lib, pkgs, ... }:

# Scrypted — NVR / camera platform. No NixOS-native service exists; the
# blessed deployment is the official container, run here declaratively as an
# OCI container on Docker with NVIDIA passthrough (RTX 2070) for hardware
# decode + object detection.
#
# - Host networking: cameras (ONVIF/RTSP discovery) and HomeKit need mDNS +
#   SSDP on the LAN, which require the host network namespace.
# - GPU via the NVIDIA container toolkit (CDI). The :nvidia image bundles the
#   CUDA/NVDEC bits; the host driver comes from modules/nvidia.nix.
# - Config volume at /var/lib/scrypted (migrated from the old TrueNAS box:
#   plugins/ + scrypted.db/).
# - NVR recording is intentionally NOT configured yet (no /nvr mount).
#
# Web UI: https://192.168.1.10:10443 (self-signed).
{
  virtualisation.docker.enable = true;
  hardware.nvidia-container-toolkit.enable = true;

  # Host avahi for HomeKit mDNS advertisement. Scrypted's HomeKit plugin is
  # configured to use the "avahi" advertiser (carried over from TrueNAS); the
  # container delegates mDNS to the host's avahi over D-Bus. Without this it
  # falls back to the built-in "ciao" responder, which is unreliable for
  # multiple HomeKit accessories — the cause of "accessory not found".
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      addresses = true;
      userServices = true;
    };
  };

  virtualisation.oci-containers = {
    backend = "docker";
    containers.scrypted = {
      image = "ghcr.io/koush/scrypted:nvidia";
      extraOptions = [
        "--network=host"
        # CDI device — NixOS's nvidia-container-toolkit generates the
        # nvidia.com/gpu CDI spec; this exposes the 2070 to the container.
        "--device=nvidia.com/gpu=all"
      ];
      environment = {
        NVIDIA_VISIBLE_DEVICES     = "all";
        NVIDIA_DRIVER_CAPABILITIES = "all";
      };
      volumes = [
        "/var/lib/scrypted:/server/volume"
        # Host D-Bus so the HomeKit plugin can drive the host's avahi-daemon
        # for reliable mDNS advertisement of the camera accessories.
        "/var/run/dbus:/var/run/dbus"
      ];
      autoStart = true;
    };
  };

  # Web UI :10443; mDNS :5353/udp for camera + HomeKit discovery.
  networking.firewall.allowedTCPPorts = [ 10443 ];
  networking.firewall.allowedUDPPorts = [ 5353 ];

  # HomeKit (HAP) accessory ports + camera HKSV/SRTP streaming use dynamic
  # high ports assigned per-accessory (observed 31775–39313, and they shift
  # on restart / when cameras are added). mDNS discovery works without these,
  # but the actual pairing + streaming TCP/UDP connection is blocked →
  # "unable to add accessory". Open the high-port range.
  #
  # Safe despite the breadth: the box has no inbound WAN exposure (remote
  # access is the outbound-only Cloudflare tunnel; no port-forwarding on the
  # router), so in practice only LAN devices can reach these ports.
  networking.firewall.allowedTCPPortRanges = [ { from = 31000; to = 65535; } ];
  networking.firewall.allowedUDPPortRanges = [ { from = 31000; to = 65535; } ];
}
