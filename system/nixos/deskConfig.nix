# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).
{ desktop, username }:

{ pkgs, ... }:

{
  networking.hostName = "ruxy-nixos"; # Define your hostname.
  networking.useDHCP = false;
  networking.bridges = {
    "br0" = {
      interfaces = [ "enp7s0" ];
    };
  };
  networking.interfaces.br0.ipv4.addresses = [ {
    address = "192.168.1.69";
    prefixLength = 24;
  } ];
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = ["192.168.1.1" "8.8.8.8"];
  networking.hosts."127.0.0.1" = [ "this.pre-initializes.the.dns.resolvers.invalid." ];
  networking.enableIPv6 = false;
  # Make sure opengl is enabled
  # Make sure opengl is enabled
  hardware = {
      opengl.extraPackages= with pkgs; [
          vaapiVdpau
              libvdpau-va-gl
              amdvlk
      ];
  };
  networking.firewall.enable = false;
  virtualisation.docker.rootless = {
  enable = true;
  setSocketVariable = true;
};



  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.videoDrivers = ["amdgpu"];
  services.xserver.windowManager.dwm.enable = true;
  services.xserver.displayManager.setupCommands = ''
   ${pkgs.xorg.xrandr}/bin/xrandr --output DP-3 --mode 2560x1440 --output HDMI-1 --mode 1920x1080 --left-of DP-3
  '';
   services.xserver.displayManager = {
		autoLogin = {
			enable = true;
			user = "ruxy";
		};
	};


  

  # Configure keymap in X11
  services.xserver.layout = "us";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ruxy = {
    isNormalUser = true;
    extraGroups = [ "docker" "wheel" "libvirtd" "kvm" "input" "disk" "libvirtd" "video" "audio"]; # Enable ‘sudo’ for the user.
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
    # Virt stuff
    virt-manager
    virt-viewer
    win-virtio
    OVMF
    qemu
    qemu_kvm
    #####
    write_stylus
    libimobiledevice
    freecad
  ];
  systemd.tmpfiles.rules = [
	  "f /dev/shm/looking-glass 0660 ruxy qemu-libvirtd -"
  ];
  
  # more virt
  virtualisation.libvirtd = {
		enable = true;
	};
  # CHANGE: add your own user here
  users.groups.libvirtd.members = [ "root" "ruxy"];
  virtualisation.libvirtd.qemu.verbatimConfig = ''
    nvram = [ "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd" ]
  '';
  services.udev.extraRules = ''
      # UDEV rules for Teensy USB devices
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
      KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"
  '';
  nixpkgs.overlays = [
    (self: super: {
        dwm = super.dwm.overrideAttrs(_: {
          src = builtins.fetchGit {
        	url = "git@github.com:OriginalOrangeXD/dwm-ruxy.git";
        	rev = "f7113e9907b4ed31444059a2251eebe501cde4d0";
        };
    });
   })
  ];
}

