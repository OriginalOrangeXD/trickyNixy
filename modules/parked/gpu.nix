{ config, lib, pkgs, ... }:

{
  # NVIDIA proprietary driver (3080 Ti for compute, headless) +
  # AMD amdgpu (drives any displays). Nouveau blacklisted so the
  # proprietary nvidia module owns the NVIDIA card.
  boot.blacklistedKernelModules = [ "nouveau" ];

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
  };

  # CUDA binary cache — without this, CUDA builds compile from source for hours.
  nix.settings = {
    substituters = [
      "https://cache.nixos.org"
      "https://cache.nixos-cuda.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "cache.nixos-cuda.org-1:OZUlbe5p2GjNYUEAh5+kDR9HuxIGZUxlZTPtuoY1bZ0="
    ];
  };

  # `videoDrivers` is the canonical entry point even when X is not running;
  # it pulls in the kernel module and userspace libs.
  services.xserver.videoDrivers = [ "nvidia" "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;                    # GA102 works open, but proprietary is more compatible for CUDA
    nvidiaSettings = false;          # headless — no GUI tool
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    powerManagement.enable = false;
  };
}
