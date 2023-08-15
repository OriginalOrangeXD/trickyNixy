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
  networking.wireless.enable = true;
  networking.wireless.userControlled.enable = true;
  networking.useDHCP = true;
  networking.wireless.environmentFile = "/home/ruxy/.env/wireless.env";
  networking.wireless.networks."Max" = { 
    hidden = true;
    auth = ''
      key_mgmt=WPA-PSK
      psk="@PSK_HOME@"
    '';
};



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
  environment.systemPackages = with pkgs; [
      xorg.xbacklight
      sutils
  ];
}

