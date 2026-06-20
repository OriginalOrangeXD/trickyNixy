{ config, lib, pkgs, ... }:

# NVIDIA proprietary driver for the RTX 2070 (TU106). Purpose on this box
# is exclusively NVENC/NVDEC for Jellyfin hardware transcoding — no CUDA,
# no compute, no display. Nouveau blacklisted so the proprietary module
# owns the card.
#
# After deploy + reboot:
#   - `nvidia-smi` should report the 2070 and 0 MiB used by anything
#   - `/dev/nvidia0`, `/dev/nvidiactl`, `/dev/nvidia-uvm` should exist
#   - jellyfin (running as `media:media`, member of `video` + `render`)
#     can open those devices and ffmpeg's nvenc encoder is available.
#
# In the Jellyfin web UI:
#   Settings → Playback → Hardware acceleration → "Nvidia NVENC"
#   Enable hardware decoding for H.264, HEVC, AV1 (the 2070 supports all).
#   Enable tone mapping for HDR-to-SDR.
{
  boot.blacklistedKernelModules = [ "nouveau" ];

  # Proprietary nvidia driver is unfree. Required.
  nixpkgs.config.allowUnfree = true;

  # The canonical entry point for the kernel module + userspace libs even on
  # a headless host (no X server actually runs).
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable      = true;
    enable32Bit = true;          # some ffmpeg / VAAPI paths still want 32-bit libs
  };

  hardware.nvidia = {
    modesetting.enable    = true;
    open                  = false;     # closed-source kernel module — broadest compat
    nvidiaSettings        = false;     # headless — no GUI control panel needed
    package               = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = false;
  };
}
