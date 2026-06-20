{ config, pkgs, lib, ... }:

let
  # Status-bar helpers for the tmux gruvbox bar. Each prints one line with a
  # Nerd Font icon (kmscon + a nerd-font SSH terminal render these); they set
  # their own PATH since tmux runs them with a minimal environment.
  tmuxWifi = pkgs.writeShellScript "tmux-wifi" ''
    export PATH=${lib.makeBinPath [ pkgs.networkmanager pkgs.coreutils pkgs.gnugrep ]}
    line=$(nmcli -t -f ACTIVE,SSID,SIGNAL dev wifi 2>/dev/null | grep '^yes' | head -1)
    if [ -z "$line" ]; then printf ' off'; exit 0; fi
    ssid=$(printf '%s' "$line" | cut -d: -f2)
    sig=$(printf '%s' "$line" | cut -d: -f3)
    printf ' %s %s%%' "$ssid" "$sig"
  '';
  tmuxBattery = pkgs.writeShellScript "tmux-battery" ''
    export PATH=${lib.makeBinPath [ pkgs.coreutils ]}
    b=/sys/class/power_supply/BAT1
    [ -r "$b/capacity" ] || exit 0
    cap=$(cat "$b/capacity")
    st=$(cat "$b/status" 2>/dev/null)
    if   [ "$cap" -ge 90 ]; then g=""
    elif [ "$cap" -ge 65 ]; then g=""
    elif [ "$cap" -ge 40 ]; then g=""
    elif [ "$cap" -ge 15 ]; then g=""
    else g=""; fi
    case "$st" in Charging|Full) bolt=" " ;; *) bolt="" ;; esac
    printf '%s%s %s%%' "$bolt" "$g" "$cap"
  '';
  # Runs AFTER gruvbox loads and owns status-right, so it isn't clobbered. Sets
  # a self-contained gruvbox-coloured right side: wifi, battery, clock, host.
  tmuxStatusPatch = pkgs.writeShellScript "tmux-status-patch" ''
    export PATH=${lib.makeBinPath [ pkgs.tmux ]}
    tmux set -g status-interval 10
    tmux set -g status-right "#[bg=#504945,fg=#fabd2f]  #(${tmuxWifi})  #[fg=#fe8019] #(${tmuxBattery})  #[fg=#a89984]%Y-%m-%d %H:%M #[bg=#bdae93,fg=#3c3836] #h "
  '';

  # kitty config for the cage console. JetBrainsMono Nerd Font is a true vector
  # font (renders at any DPI-scaled size, unlike the bitmap Terminess which
  # rendered as boxes). Plain gruvbox-dark background — no image — for the most
  # legible text. font_size is DPI-scaled by Wayland — tune to taste.
  kittyConf = pkgs.writeText "kitty.conf" ''
    font_family             JetBrainsMono Nerd Font Mono
    font_size               16
    # plain gruvbox-dark background, no image — maximum text legibility
    background              #282828
    foreground              #ebdbb2
    cursor_blink_interval   0
    confirm_os_window_close 0
    enabled_layouts         tall,stack
  '';

  # cage runs a single program; wrap kitty with its config path.
  cageKitty = pkgs.writeShellScript "cage-kitty"
    "exec ${pkgs.kitty}/bin/kitty --config ${kittyConf}";
in

# NixOS configuration for the bastion laptop at 192.168.1.90.
#
# Role: SSH jump host / admin workstation. This box exists to get INTO other
# machines — it almost never runs workloads of its own. Terminal-only: no
# desktop, no display manager, no X session. The only "screen" is the Linux
# console (TTY), so the visual config here is the console keymap + font.
#
#   - Keyboard: Colemak on the console (the stock install also set the X11
#     colemak variant, but X never runs here; console.keyMap is what matters).
#   - Font: Terminus, large (ter-132n), applied early in boot.
#   - Lid: close → suspend (screen off, ~0.5W); wakes on lid-open. Not
#     SSH-reachable while suspended.
#
# Deploy from the MacBook (build-host = target-host because the aarch64-darwin
# laptop cannot build x86_64-linux):
#   nixos-rebuild switch \
#     --flake .#bastion \
#     --target-host robby@192.168.1.90 \
#     --build-host  robby@192.168.1.90 \
#     --use-remote-sudo
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/mosh.nix
  ];

  # ── Nix settings ────────────────────────────────────────────────────────
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.gc = {
    automatic = true;
    dates     = "weekly";
    options   = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;
  nixpkgs.config.allowUnfree = true;

  # ── Identity ────────────────────────────────────────────────────────────
  networking.hostName = "bastion";
  # WiFi laptop; NetworkManager from the stock install. .90 is a DHCP
  # reservation on the UniFi LAN (same pattern as the other hosts).
  networking.networkmanager.enable = true;

  time.timeZone      = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";

  # ── Terminal-only: console keymap + pretty font ──────────────────────────
  # No GUI at all. services.xserver stays disabled (default). The console is
  # the whole interface, so configure it properly.
  console = {
    keyMap    = "colemak";                 # kbd ships the `colemak` keymap
    packages  = [ pkgs.terminus_font ];
    font      = "ter-132n";                # large, crisp Terminus
    earlySetup = true;                     # apply font before stage-1 finishes
  };

  # ── Rich local console: cage + kitty on tty1 ────────────────────────────
  # The kernel VT can't show Nerd Font icons, truecolor, OR a background image.
  # So we run a single-app Wayland kiosk: cage (wlroots compositor) launches
  # kitty fullscreen on tty1 — cage-tty1.service replaces getty@tty1 and pulls
  # in graphical.target. kitty gives Nerd Font glyphs, truecolor, AND a real
  # background_image. keyd still sits BELOW cage at the evdev layer (home-row
  # mods + capslock→ctrl intact); the colemak layout comes from XKB_DEFAULT_*.
  # console.* + the getty autologin (tty2-6) stay as a plain kernel-VT fallback
  # if cage ever fails to start; SSH is the other safety net.
  hardware.graphics.enable = true;                     # mesa/GL for wlroots
  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono   # vector Nerd Font for kitty (icons)
    pkgs.noto-fonts-color-emoji      # emoji fallback (starship 🌐/❄️ etc.) → no tofu boxes
  ];
  services.cage = {
    enable  = true;
    user    = "robby";
    program = cageKitty;
    environment = {
      XKB_DEFAULT_LAYOUT  = "us";
      XKB_DEFAULT_VARIANT = "colemak";
    };
  };
  # Plain kernel-VT autologin on the OTHER VTs (tty2-6) as a fallback console,
  # and so password entry (mangled by colemak + home-row mods) is never needed.
  services.getty.autologinUser = "robby";

  # ── Home-row mods + CapsLock→Ctrl on the bare console ────────────────────
  # keyd intercepts at the evdev layer, so this works on the TTY with no GUI.
  # It runs BEFORE the kernel VT keymap, so `overload(mod, <key>)` emits the
  # physical keycode on tap (the colemak map above then turns it into the right
  # letter) and the modifier on hold. Keys below are named by PHYSICAL (QWERTY)
  # position; the comment shows the colemak letter each one produces.
  #
  # Symmetric home-row mods, pinky→index = Super / Alt / Ctrl / Shift,
  # mirroring the layout on the MacBook:
  #   a/o → Super   r/i → Alt   s/e → Ctrl   t/n → Shift
  #
  # Uses keyd's purpose-built `lettermod(layer, key, idle, hold)` macro (the
  # documented home-row-mods primitive): the key resolves INSTANTLY to its
  # letter if struck within `idle` ms of another key (mid-word rolls never
  # misfire), and only acts as a modifier when struck after a typing pause and
  # held past `hold` ms. Tuning if you still get mistypes:
  #   • letters still coming out as modifiers mid-word → raise idle (150→180…)
  #   • modifiers feel unreachable / laggy            → lower hold  (200→160…)
  #
  # NOTE: this only affects the bastion's LOCAL console; SSH sessions into the
  # box are unaffected (keyd sits on the physical keyboard, not the ptys).
  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings.main = {
        capslock  = "layer(control)";                # extra Ctrl, independent of HRM
        a         = "lettermod(meta, a, 150, 200)";      # colemak a → Super
        s         = "lettermod(alt, s, 150, 200)";       # colemak r → Alt
        d         = "lettermod(control, d, 150, 200)";   # colemak s → Ctrl
        f         = "lettermod(shift, f, 150, 200)";     # colemak t → Shift
        j         = "lettermod(shift, j, 150, 200)";     # colemak n → Shift
        k         = "lettermod(control, k, 150, 200)";   # colemak e → Ctrl
        l         = "lettermod(alt, l, 150, 200)";       # colemak i → Alt
        semicolon = "lettermod(meta, semicolon, 150, 200)"; # colemak o → Super
      };
    };
  };

  # ── Lid close → suspend (screen off + ~0.5W standby) ─────────────────────
  # Closing the lid suspends to RAM and wakes on lid-open. NOTE: while
  # suspended the box is NOT SSH-reachable — open the lid to wake it. (Earlier
  # this was "ignore" to keep it reachable shut; changed to suspend for battery.)
  services.logind.settings.Login = {
    HandleLidSwitch              = "suspend";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked        = "suspend";
  };

  # ── Bootloader ──────────────────────────────────────────────────────────
  boot.loader.systemd-boot.enable      = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ── Deploy / admin user ──────────────────────────────────────────────────
  # Same ed25519 key authorized on the box today (and on the other hosts),
  # reused verbatim so hardening SSH cannot lock us out.
  users.users.robby = {
    isNormalUser = true;
    description  = "Robert (deploy / admin)";
    extraGroups  = [ "wheel" "networkmanager" "video" ];  # video = write backlight
    # Linger so robby's user systemd instance (and the tmux auto-save timer)
    # keeps running after SSH logout — the tmux server outlives the login, so
    # its auto-save must too.
    linger = true;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG7WQgXfplk8FlV5CgyKxHaLRpTMtJcyct3s6ADdOYJ9 robby@Roberts-MacBook-Pro.local"
    ];
  };

  # Passwordless sudo for `wheel` so deploys after the first are hands-free.
  security.sudo.wheelNeedsPassword = false;

  # ── SSH ───────────────────────────────────────────────────────────────────
  # Inbound 22: this is the jump host, so we SSH *in* and then SSH back *out*.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  # ── Firewall ──────────────────────────────────────────────────────────────
  # 22 ssh on the LAN. mosh opens its own UDP range via ../../modules/mosh.nix.
  networking.firewall.allowedTCPPorts = [ 22 ];

  # ── Brightness keys on a terminal-only laptop ────────────────────────────
  # No desktop daemon exists to catch the brightness keys, so they're inert by
  # default. `illum` is a tiny evdev-level daemon that handles the brightness
  # keys with no X/GUI/logind-seat — purpose-built for headless/console boxes.
  # It drives the confirmed amdgpu_bl1 backlight. `brightnessctl` gives manual
  # control (`brightnessctl set 10%`) and ships the udev rules that let the
  # `video` group write backlight without root.
  services.illum.enable = true;
  # brightnessctl's package ships a udev rule that chgrps the backlight to
  # `video` and makes it group-writable — without this, only root can set
  # brightness and `brightnessctl set` as robby fails. (illum runs as root, so
  # the keys work either way; this is for manual CLI control.)
  services.udev.packages = [ pkgs.brightnessctl ];

  # ── IPv6 address-selection fix (same LAN-wide ULA-IPv6 trap as the other
  #    hosts) ──────────────────────────────────────────────────────────────
  # The UniFi LAN hands out ULA IPv6 with no global uplink; glibc prefers IPv6,
  # so dual-stacked hosts can hang on a dead AAAA. Prefer IPv4. Keeps IPv6 on.
  environment.etc."gai.conf".text = "precedence ::ffff:0:0/96  100\n";

  # ── Pretty shell prompt across the box ───────────────────────────────────
  programs.starship = {
    enable = true;
    # Starship's default 🌐 (ssh) and ❄️ (nix-shell) symbols are emoji, which
    # render as tofu boxes in any terminal without a colour-emoji font — e.g.
    # the "2 red boxes" from the 2-cell 🌐 when viewed over SSH. Emit nothing
    # for those symbols so the prompt is box-proof everywhere (Noto Color Emoji
    # is installed as a local backstop, but not emitting them is more robust).
    settings = {
      hostname.ssh_symbol = "";
      nix_shell.symbol = "";
    };
  };

  # ── tmux: gruvbox theme + saved/restored sessions ────────────────────────
  # Plugins are Nix-managed (no TPM). The programs.tmux module emits extraConfig
  # AFTER its own `plugins` run-shell lines, but plugins read their @options at
  # load time — so we DON'T use the `plugins` option; we set options first and
  # source plugins ourselves (via each plugin's `.rtp`) at the end, theme first
  # so resurrect sees the final status line.
  #
  # Session saving: resurrect is the engine (manual keys below). We do NOT use
  # tmux-continuum for auto-save — its trigger relies on a status-right
  # interpolation gated by a process-count heuristic that doesn't fire reliably
  # on this tmux 3.6a setup (verified: the interpolation never lands). Instead a
  # deterministic systemd user timer (below) runs resurrect's save every 15 min.
  #   • prefix + Ctrl-s → save now    • prefix + Ctrl-r → restore
  #   • timer keeps a fresh snapshot so a reboot loses ≤15 min of layout.
  programs.tmux = {
    enable       = true;
    clock24      = true;
    historyLimit = 50000;
    baseIndex    = 1;        # windows start at 1
    escapeTime   = 0;        # snappy ESC (matters under vim)
    terminal     = "tmux-256color";
    extraConfig = ''
      # truecolor passthrough (renders the theme properly over SSH)
      set -ga terminal-overrides ",*256col*:Tc"
      set -as terminal-features ",*:RGB"

      set -g mouse on
      set -g renumber-windows on
      set -g set-clipboard on
      setw -g pane-base-index 1

      # quick reload + intuitive splits that keep the current dir
      bind r source-file /etc/tmux.conf \; display "tmux.conf reloaded"
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # ── plugin options (MUST precede the run-shell lines below) ──
      set -g @tmux-gruvbox 'dark'
      set -g @resurrect-capture-pane-contents 'on'

      # ── source plugins last (theme before resurrect); status patch AFTER
      #    gruvbox so our wifi/battery status-right survives ──
      run-shell ${pkgs.tmuxPlugins.sensible.rtp}
      run-shell ${pkgs.tmuxPlugins.gruvbox.rtp}
      run-shell ${pkgs.tmuxPlugins.resurrect.rtp}
      run-shell ${tmuxStatusPatch}
    '';
  };

  # Deterministic tmux auto-save: every 15 min, save the live sessions via
  # resurrect IF a server is running. Replaces tmux-continuum's unreliable
  # status-bar trigger with a plain systemd user timer.
  systemd.user.services.tmux-resurrect-save = {
    description = "Auto-save tmux sessions (resurrect)";
    serviceConfig.Type = "oneshot";
    # Interactive shells set TMUX_TMPDIR=$XDG_RUNTIME_DIR, so the real server
    # socket is at /run/user/UID/tmux-UID/default — not the /tmp default. Point
    # the service at the same dir (%t = runtime dir) or it saves a stale server.
    serviceConfig.Environment = "TMUX_TMPDIR=%t";
    # save.sh has a `#!/usr/bin/env bash` shebang and calls bare tmux, awk,
    # grep, sed, ps, tar + coreutils; the user-service PATH is otherwise empty,
    # so provide them all (a missing one exits 127). bash is needed for the
    # env-shebang; procps=ps, gnutar=tar (pane-content capture).
    path = with pkgs; [ bash tmux gawk gnugrep gnused coreutils gnutar procps ];
    script = ''
      if tmux has-session 2>/dev/null; then
        ${pkgs.tmuxPlugins.resurrect}/share/tmux-plugins/resurrect/scripts/save.sh quiet
      fi
    '';
  };
  systemd.user.timers.tmux-resurrect-save = {
    description = "Periodic tmux session auto-save";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec       = "15min";
      OnUnitActiveSec = "15min";
    };
  };

  # ── Packages: SSH-client tooling + lean admin/CLI niceties ───────────────
  environment.systemPackages = with pkgs; [
    # SSH / jump tooling
    openssh
    autossh            # keep tunnels alive
    sshfs              # mount remote filesystems over SSH
    wireguard-tools
    # editor (tmux comes from programs.tmux below)
    vim
    # network diagnostics (jump host wants these handy)
    mtr
    nmap
    dig
    whois
    iperf3
    # backlight control (illum handles the keys; this is for manual set)
    brightnessctl
    # admin basics
    git
    wget
    curl
    htop
    btop
    fastfetch
    lsof
    file
    tree
    rsync
    # pretty/modern CLI
    eza
    bat
    fd
    ripgrep
    fzf
    zoxide
  ];

  # stateVersion matches the live install on the box (verified 26.05).
  system.stateVersion = "26.05";
}
