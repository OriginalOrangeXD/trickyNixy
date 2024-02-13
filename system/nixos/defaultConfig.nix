# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ pkgs, ... }:
{
  nix.settings.trusted-users = [ "root" "robby" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  services.usbmuxd.enable = true;	

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/New_York";
  virtualisation.docker.enable = true;

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkbOptions in tty.
  };
    # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;


  environment.systemPackages = with pkgs; [
    typst-lsp
    vim 
    gcc_multi
    docker
    go
    bluez
    zathura
    ripgrep
    wget
    corectrl
    clang-tools
    arduino
    nnn
    dmenu
    alacritty
    emacs
    st
    neofetch
    kitty
    gh
    terminus_font
    starship
    git
    busybox
    starship
    feh
    tldr
    zsh
    unzip
    arduino-cli
    flameshot
    nerdfonts
    rust-analyzer
    arduino-language-server
    cachix
    teensy-loader-cli
    platformio
    poetry
    killall
    bat
    openssl
    gccgo13
    keepassxc
    thefuck
    tmux
    nitrogen
    neovim
  ];
  
programs.zsh = {
	enable = true;
	shellAliases = {
		ll = "ls -l";
		update = "sudo nixos-rebuild switch";
	};
  interactiveShellInit = ''
	eval "$(starship init zsh)"
    '';
 ohMyZsh = {
    enable = true;
    plugins = [ "git" "thefuck" ];
  };
};
fonts ={
    packages = 
        with pkgs; [
        (nerdfonts.override { fonts = [ "Agave" ]; })
        ];
          fontconfig = {
    defaultFonts = {
      monospace = [ "AgaveNerdFontMono-Regular" ];
    };
  };
};

    services.udev.extraRules = ''
      # UDEV rules for Teensy USB devices
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", ENV{ID_MM_DEVICE_IGNORE}="1"
      ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789A]?", ENV{MTP_NO_PROBE}="1"
      SUBSYSTEMS=="usb", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789ABCD]?", MODE:="0666"
      KERNEL=="ttyACM*", ATTRS{idVendor}=="16c0", ATTRS{idProduct}=="04[789B]?", MODE:="0666"
  '';
  services.udev.packages = [ 
      pkgs.platformio
      pkgs.openocd
  ];
  services.blueman.enable = true;
  services.gvfs.enable = true;

}


