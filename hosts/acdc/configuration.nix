{
    pkgs,
    inputs,
    ...
}:

{
  imports = [
    ./hardware.nix
    ./temp.nix
    inputs.home-manager.nixosModules.default
  ];

  config = {
    nixpkgs.hostPlatform.system = "x86_64-linux";
    system.stateVersion = "23.05";

### NETWORKING ###
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
######

    networking.firewall.enable = false;
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
    virtualisation.docker.rootless = {
      enable = true;
      setSocketVariable = true;
    };
    users.users.ruxy = {
      isNormalUser = true;
      extraGroups = [ "docker" "wheel" "libvirtd" "kvm" "input" "disk" "libvirtd" "video" "audio"]; # Enable ‘sudo’ for the user.
        packages = with pkgs; [
        lutris
          steam
          xfce.thunar
          cura
          firefox
          arduino
          discord
          tree
          obs-studio
        ];
    };
    services.nix-serve = {
      enable = true;
      secretKeyFile = "/home/ruxy/keys/cache-priv-key.pem";
    };
    programs.steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
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
        spice
#####
        write_stylus
        libimobiledevice
        freecad
        (lutris.override {
         extraPkgs = pkgs: [
         wineWowPackages.stable
         winetricks
         ];
         })

    ];
    systemd.tmpfiles.rules = [
      "f /dev/shm/looking-glass 0660 ruxy qemu-libvirtd -"
    ];

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users = { 
      "ruxy" = import ./home.nix; 
    };
  };

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
# quest
      SUBSYSTEM="usb", ATTR{idVendor}=="2833", ATTR{idProduct}=="0186", MODE="0660" group="plugdev", symlink+="ocuquest%n"

      '';
    services = {
      syncthing = {
        enable = true;
        user = "ruxy";
        dataDir = "/home/ruxy/syncthing";
        configDir = "/home/ruxy/syncthing/.config/syncthing";
        overrideDevices = true;     # overrides any devices added or deleted through the WebUI
          overrideFolders = true;     # overrides any folders added or deleted through the WebUI
          devices = {
            "touch" = { id = "UTCVJC7-GLJRFVT-HP2AW2J-KSVJVUU-F5JVJG3-LKR2CSJ-BF5K45V-O7Z3AAP"; };
            "boox" = { id =  "YQYN5TV-K7IPUBA-LYOMHSB-HR2R7IF-C4PUAKP-Q237CBU-D7ZJKZO-N4MLDQZ"; };
          };
        folders = {
          "Music" = {        # Name of folder in Syncthing, also the folder ID
            path = "/home/ruxy/Music";    # Which folder to add to Syncthing
              devices = [ "touch" "boox" ];      # Which devices to share the folder with
          };
          "Books" = {        # Name of folder in Syncthing, also the folder ID
            path = "/home/ruxy/Books";    # Which folder to add to Syncthing
              devices = [ "touch" "boox" ];      # Which devices to share the folder with
          };
        };
      };
    };
    services.openssh = {
      enable = true;
# require public key authentication for better security
      settings.PasswordAuthentication = true;
      settings.KbdInteractiveAuthentication = false;
#settings.PermitRootLogin = "yes";
    };
	  programs.hyprland.enable = true;
  };
}

