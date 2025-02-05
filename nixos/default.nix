{pkgs, ... }: {
  imports = [
    ./font.nix
    ./postgres.nix
    ./zsh.nix
    ./sound.nix
    ./bluetooth.nix
    ./teensy.nix
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  services.usbmuxd.enable = true;	
  services.tailscale.enable = true;
  programs.adb.enable = true;


  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Set your time zone.
  time.timeZone = "America/New_York";
  environment.systemPackages = with pkgs; [
    atkinson-hyperlegible
    kanshi
    alsa-utils
    swaynotificationcenter
    picotool
    lynx
    socat
    jq
    swww
    qmk
    qmk_hid
    qmk-udev-rules
    unixtools.procps
    obsidian
    nextcloud-client
    typst-lsp
    vim 
    libva
    gcc_multi
    docker
    go
    bluez
    zathura
    ripgrep
    wget
    corectrl
    clang-tools
    nnn
    dmenu
    networkmanagerapplet
    xwaylandvideobridge
    alacritty
    emacs
    st
    godot_4
    neofetch
    kitty
    gh
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
    rust-analyzer
    hyprpaper
    poetry
    killall
    cachix
    bat
    openssl
    gccgo13
    keepassxc
    thefuck
    tmux
    nitrogen
  ];
  services.xserver = {
    windowManager.leftwm.enable = true;
    layout = "us,dh";
    xkb = {
      extraLayouts.dh = {
        description = "Colemak-DH ergo";
        languages = ["eng"];
        symbolsFile = ../symbols/colemak_dh;
    };
   options = "terminate:ctrl_alt_bksp";
    };
  };
}
