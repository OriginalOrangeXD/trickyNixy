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
  networking.useDHCP = false;
  networking.bridges = {
    "br0" = {
      interfaces = [ "enp7s0" ];
    };
  };
  networking.interfaces.br0.ipv4.addresses = [ {
    address = "192.168.2.203";
    prefixLength = 24;
  } ];
  networking.defaultGateway = "192.168.2.1";
  networking.nameservers = ["192.168.2.1" "8.8.8.8"];

  # Set your time zone.
  time.timeZone = "America/NewYork";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true; # use xkbOptions in tty.
  };
# Make sure opengl is enabled
  hardware = {
	  opengl.extraPackages= with pkgs; [
	      vaapiVdpau
	      libvdpau-va-gl
	      amdvlk
    ];
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

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

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
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    corectrl
    nodejs_18
    dwm
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
    starship
    feh
    tldr
    zsh
    unzip
    xfce.thunar
    qemu
    # Virt stuff
    virt-manager
    virt-viewer
    win-virtio
    OVMF
    qemu
    virtmanager
    qemu_kvm
    #####
    rustup
    arduino-cli
    rustc
    cargo
    cargo-generate
    wasm-pack 
    flameshot
    nerdfonts
    rust-analyzer
    nodePackages_latest.typescript-language-server
    arduino-language-server
    looking-glass-client
    cachix
    xorg.xinit
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
  programs.steam = {
	enable = true;
	remotePlay.openFirewall = true;
	dedicatedServer.openFirewall = true;
};
  services.picom.enable = true;
  
  # more virt
  virtualisation.libvirtd = {
		enable = true;
	};

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
  
  # CHANGE: add your own user here
  users.groups.libvirtd.members = [ "root" "ruxy"];
  virtualisation.libvirtd.qemu.verbatimConfig = ''
    nvram = [ "${pkgs.OVMF}/FV/OVMF.fd:${pkgs.OVMF}/FV/OVMF_VARS.fd" ]
  '';
  ####################
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}

