# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running `nixos-help`).

{ pkgs, ... }:
{
  nix.settings.trusted-users = [ "root" "ruxy" ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  services.usbmuxd.enable = true;	

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/NewYork";
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
    vim 
    gcc_multi
    docker
    go
    tetex
    texlive.combined.scheme-full
    bluez
    zathura
    ripgrep
    wget
    corectrl
    nodejs_18
    dwm
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
    glxinfo
    rofi
    steam
    git
    busybox
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
    nodePackages_latest.typescript-language-server
    arduino-language-server
    looking-glass-client
    cachix
    teensy-loader-cli
    platformio
    avrdude
    nodePackages_latest.gitmoji-cli
    xorg.xinit
    poetry
    lutris
    killall
    bat
    openssl
    picom
    libgccjit
    gccgo13
    keepassxc
    thefuck
    tmux
    nitrogen
    neovim
    kdenlive
    mediainfo 
    glaxnimate
    audacity
    cura
    gst_all_1.gstreamer
# Common plugins like "filesrc" to combine within e.g. gst-launch
    gst_all_1.gst-plugins-base
# Specialized plugins separated by quality
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
# Plugins to reuse ffmpeg to play almost every video format
    gst_all_1.gst-libav
# Support the Video Audio (Hardware) Acceleration API
    gst_all_1.gst-vaapi
    pcmanfm
    (lutris.override {
	extraPkgs = pkgs: [
		wineWowPackages.stable
		winetricks
	];
	})
  ];
  programs.steam = {
	enable = true;
	remotePlay.openFirewall = true;
	dedicatedServer.openFirewall = true;
};
  services.picom.enable = true;
  
    programs.tmux = {
    enable = true;
    shortcut = "b";
    # aggressiveResize = true; -- Disabled to be iTerm-friendly
    baseIndex = 1;
    newSession = true;
    # Stop tmux+escape craziness.
    escapeTime = 0;
    # Force tmux to use /tmp for sockets (WSL2 compat)
    secureSocket = false;

    plugins = with pkgs; [
      tmuxPlugins.better-mouse-mode
    ];

    extraConfig = ''
      set -g default-terminal "xterm-256color"
      set -ga terminal-overrides ",*256col*:Tc"
      set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'
      set-environment -g COLORTERM "truecolor"

      # Mouse works as expected
      set-option -g mouse on
      # easy-to-remember split pane commands
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      bind c new-window -c "#{pane_current_path}"
      run-shell ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/resurrect.tmux
      run-shell ${pkgs.tmuxPlugins.nord}/share/tmux-plugins/nord/nord.tmux
    '';
    };
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
  fonts.fonts = with pkgs; [
        (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
  ];
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

  system.stateVersion = "23.05";
}


