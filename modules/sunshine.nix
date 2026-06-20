{ config, pkgs, lib, ... }:

# Moonlight host (Sunshine) + Tailscale transport for the gaming box.
#
# Model (verified): one gamescope session runs (Jovian autoStart); the
# user-level Sunshine service captures THAT running session via KMS and serves
# the Moonlight protocol. capSysAdmin is required for KMS capture under a
# gamescope/Wayland (non-wlroots) compositor.
#
# First-run, interactive (cannot be declarative without stored secrets):
#   1. `sudo tailscale up`         — authenticate the box to the tailnet
#   2. https://<tailscale-ip>:47990 — set Sunshine admin user/pass, pair Moonlight (PIN)
#   3. log into Steam on the first stream
#
# Verify after deploy:
#   - `systemctl --user -M robby@ status sunshine` (or check the unit) is active
#   - `curl -k https://localhost:47990` returns the Sunshine login page
#   - `vainfo` lists VAEntrypointEncSlice for H264/HEVC
{
  services.sunshine = {
    enable      = true;
    autoStart   = true;
    capSysAdmin = true;   # required for DRM/KMS capture under gamescope/Wayland
    openFirewall = true;  # TCP 47984/47989/47990/48010, UDP 47998/47999/48000/48002/48010
  };

  # ── Moonlight input injection ──────────────────────────────────────────────
  # Virtual gamepad / keyboard / mouse from remote clients need uinput.
  hardware.uinput.enable = true;
  users.users.robby.extraGroups = [ "input" ];
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
  '';

  # ── Tailscale: play from anywhere, no LAN port-forwarding ──────────────────
  # Moonlight connects to the box's tailnet IP (100.x.y.z). Trusting tailscale0
  # exposes the Sunshine ports to tailnet peers only — matches Robert's standing
  # rule of no WAN port-forwarding (cf. the Cloudflare-tunnel pattern elsewhere).
  services.tailscale = {
    enable             = true;
    useRoutingFeatures = "client";
    openFirewall       = true;   # UDP 41641 for the tailscale daemon
  };
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
}
