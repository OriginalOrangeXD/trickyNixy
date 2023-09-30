# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).
{ desktop, username }:

{ pkgs, ... }:

{
  nix.settings.trusted-users = [ "root" "ruxy" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ruxy-nixos"; # Define your hostname.
  #networking.wireless.enable = true;
  #networking.wireless.userControlled.enable = true;
  #networking.useDHCP = true;
#   networking.wireless.environmentFile = "/home/ruxy/.env/wireless.env";
#   networking.wireless.networks."Max" = { 
#     hidden = true;
#     auth = ''
#       key_mgmt=WPA-PSK
#       psk="@PSK_HOME@"
#     '';
# };

networking.networkmanager.enable = true;


networking.firewall.enable = true;
  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.windowManager.dwm.enable = true;
   services.xserver.displayManager = {
		autoLogin = {
			enable = true;
			user = "ruxy";
		};
	};


  services.xserver.layout = "us";
  services.xserver.xkbVariant = "dvorak";
  services.xserver.xkbOptions = "caps:escape";
  services.xserver.dpi = 227;


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ruxy = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "kvm" "input" "disk" "libvirtd" "video" "audio"]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      firefox
      arduino
      discord
      tree
      obs-studio
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  services.power-profiles-daemon.enable = false;
  services.tlp = {
	enable = true;
	settings = {
	    USB_EXCLUDE_BTUSB=1;
	};
  };
  environment.systemPackages = with pkgs; [
      sutils
      tlp
      xbrightness
      virt-manager
      virt-viewer
      win-virtio
      OVMF
      qemu
      qemu_kvm
  ];
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 233 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/xbrightness +10000"; }
      { keys = [ 232 ]; events = [ "key" ]; command = "/run/current-system/sw/bin/xbrightness -10000"; }
    ];
  };
  virtualisation.libvirtd = {
		enable = true;
	};
  # CHANGE: add your own user here
  users.groups.libvirtd.members = [ "root" "ruxy"];
  nixpkgs.overlays = [
    (final: prev: {
      dwm = prev.dwm.overrideAttrs (old: { src = /home/ruxy/git/dwm-ruxy ;});
    })
  ];
}

