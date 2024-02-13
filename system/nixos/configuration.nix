# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
    nix.settings.experimental-features = [ "nix-command" "flakes" ];
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];
  nixpkgs.config.allowUnfree = true;
  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "ruxy-lap"; # Define your hostname.
  networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    # keyMap = "us";
    useXkbConfig = true; # use xkb.options in tty.
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Configure keymap in X11
  services.xserver.xkb.layout = "us";
  services.xserver.extraLayouts.dh = {
    description = "Colemak-DH ergo";
    languages = ["eng"];
    symbolsFile = ./colemak_dh;
  };
   
  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;


  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.robby = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "networkmanager" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      firefox
      tree
    ];
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    kitty
    git
    firefox
    neovim
    typst-lsp
    vim 
    go
    bluez
    ripgrep
    wget
    corectrl
    clang-tools
    arduino
    nnn
    st
    neofetch
    kitty
    gh
    terminus_font
    starship
    git
    starship
    feh
    tldr
    zsh
    unzip
    xfce.thunar
    arduino-cli
    flameshot
    nerdfonts
    rust-analyzer
    arduino-language-server
    cachix
discord
	wofi
    teensy-loader-cli
    platformio
    poetry
    killall
    bat
    openssl
    keepassxc
    thefuck
    tmux
    neovim
  ];
    services.udev.extraRules = ''
      # UDEV rules for Teensy USB devices
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
      KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"
	SUBSYSTEM=="usb", GROUP="spice", MODE="0660"
	SUBSYSTEM=="usb_device", GROUP="spice", MODE="0660"
  '';
  services.udev.packages = [ 
      pkgs.platformio
      pkgs.openocd
  ];
  services.blueman.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  programs.hyprland.enable=true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services.fprintd.enable =true;
  security.pam.services.login.fprintAuth = true;
  security.pam.services.xscreensaver.fprintAuth = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;


	virtualisation.libvirtd.enable = true;
	programs.virt-manager.enable = true;
  system.copySystemConfiguration = true;
  networking.bridges = {
    "br0" = {
      interfaces = [ "wlp1s0" ];
    };
  };
  networking.interfaces.br0.ipv4.addresses = [ {
    address = "172.16.20.128";
    prefixLength = 16;
  } ];

  system.stateVersion = "23.11"; # Did you read the comment?

}

