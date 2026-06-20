# Captured verbatim from the live install on 192.168.1.79 (2026-05-26) — the
# box was provisioned with a stock `nixos-generate-config` scan. Single ext4
# NVMe root, vfat /boot (systemd-boot), one swap partition, Intel CPU.
# Do not hand-edit; regenerate with `nixos-generate-config` on the box if the
# disk layout ever changes.
{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/648b84dc-cefc-449a-a1d7-5fdd919f2b8a";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/FEC6-8FBE";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices =
    [ { device = "/dev/disk/by-uuid/75321944-412e-4f0d-a1c6-b373a3000aa9"; }
    ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
