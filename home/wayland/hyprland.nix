{ config, pkgs, lib, inputs, ... }: 
{
  config = {
    home.packages = [
      pkgs.swaynotificationcenter
      pkgs.pyprland
      pkgs.killall
      pkgs.hyprlock
      # Audio Control
      pkgs.pavucontrol
      pkgs.wl-clipboard
    ];
    

    wayland.windowManager.hyprland = {
      enable = true;
      ## Bleeding edge Hyprland
      # package = inputs.hyprland.packages."${pkgs.system}".hyprland;
      settings = {
        "$terminal" = "kitty";
        "$editor" = "nvim";
        "$fileManager" = "dolphin";
        "$menu-drun" = "rofi -show drun";
        "$menu-run" = "rofi -show run";
        "$MOD" = "SUPER";
        "$LAPTOP_KB_ENABLED" = true;
        env = [
          "XCURSOR_SIZE,24"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "and"
          "MOZ_ENABLE_WAYLAND,1"
          "QT_QPA_PLATFORM,wayland"
          "SDL_VIDEODRIVER,wayland"
          "_JAVA_AWT_WM_NONREPARENTING,1"
        ];
        monitor = "eDP-1, 2256x1504@60Hz, 0x0, 1.333333 ";
        device = {
          name = "at-translated-set-2-keyboard";
          enabled = "$LAPTOP_KB_ENABLED";
        };
        exec-once = [
          "${pkgs.networkmanagerapplet}/bin/nm-applet"
          "kanshi"
          "pypr"
          "[workspace 1 silent] $terminal"
          "hyprpaper"
          "swww-daemon"
          "/home/robby/scripts/monitor-switch.sh daemon"
          "sleep 1.5 && swww img /home/robby/flake/wallpapers/wall_secondary.png"
        ];
        input = {
          kb_layout = ["dh"];
          kb_variant= [""];
        };
        general = {
          gaps_in = 5;
          gaps_out = 5;
          border_size = 2;
          layout = "master";
          allow_tearing = false;
        };
        decoration = {
          rounding = 10;
          blur = {
            enabled = true;
            size = 5;
            passes = 2;
          };
        };
        animations = {
          enabled = "yes";
          bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
          animation = [
            "windows, 1, 7, myBezier"
            "windowsOut, 1, 7, default, popin 80%"
            "border, 1, 10, default"
            "borderangle, 1, 8, default"
            "fade, 1, 7, default"
            "workspaces, 1, 6, default"
          ];
        };
        dwindle = {
          pseudotile = "yes";
          preserve_split = "yes";
        };
        gestures.workspace_swipe = "off";
        misc = {
          # Anime lady hehe
          # force_default_wallpaper = -1;
	  disable_hyprland_logo = true;
          enable_swallow = true;
          swallow_regex = [
            "^(Alacritty)$"
          ];
        };
        windowrulev2 = [
          # Pavucontrol
          "float, class:^(pavucontrol)$, title:^(Volume Control)$"
          "size 80% 85%, class:^(pavucontrol)$, title:^(Volume Control)$"
          "center, class:^(pavucontrol)$, title:^(Volume Control)$"
          
          # Pavucontrol
          "float, class:^(nm-connection-editor)$, title:^(.*)$"
          "size 80% 85%, class:^(nm-connection-editor)$, title:^(.*)$"
          "center, class:^(nm-connection-editor)$, title:^(.*)$"
          
          # Center
          "float, class:^(center)$"
          "size 80% 85%, class:^(center)$"
          "center, class:^(center)$"
        ];
        bind = [
          "$MOD, Return, exec, $terminal"
	        "$MOD, E, exec, $editor"
          "$MOD, R, exec, $menu-run"
          "$MOD, P, exec, $menu-drun"
          "$MOD, code:61, exec, $menu-window"
          "$MOD, B, exec, killall '.waybar-wrapped' || waybar"
          "$MOD_SHIFT, C, killactive, "
          "$MOD, C, killactive, "
          "$MOD_SHIFT, Q, exit,"
        
          # Move focus with mainMod + arrow keys
          "$MOD, H, layoutmsg, swapprev"
          "$MOD, L, layoutmsg, swapnext"
          "$MOD, K, layoutmsg, cycleprev"
          "$MOD, J, layoutmsg, cyclenext"
          "$MOD_SHIFT, Return, layoutmsg, focusmaster"
          "$MOD, O, layoutmsg, orientationcycle top left center"
          "$MOD, F, fullscreen"
          "$MOD, M, fullscreen, 1"
          "$MOD, W, togglefloating"
          "$MOD, TAB, cyclenext"
          "$MOD, TAB, bringactivetotop"

          # Switch workspaces with mainMod + [0-9]
          "$MOD, 1, workspace, 1"
          "$MOD, 2, workspace, 2"
          "$MOD, 3, workspace, 3"
          "$MOD, 4, workspace, 4"
          "$MOD, 5, workspace, 5"
          "$MOD, 6, workspace, 6"
          "$MOD, 7, workspace, 7"
          "$MOD, 8, workspace, 8"
          "$MOD, 9, workspace, 9"
          "$MOD, 0, workspace, 0"
        
          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "$MOD SHIFT, 1, movetoworkspace, 1"
          "$MOD SHIFT, 2, movetoworkspace, 2"
          "$MOD SHIFT, 3, movetoworkspace, 3"
          "$MOD SHIFT, 4, movetoworkspace, 4"
          "$MOD SHIFT, 5, movetoworkspace, 5"
          "$MOD SHIFT, 6, movetoworkspace, 6"
          "$MOD SHIFT, 7, movetoworkspace, 7"
          "$MOD SHIFT, 8, movetoworkspace, 8"
          "$MOD SHIFT, 9, movetoworkspace, 9"
          "$MOD SHIFT, 0, movetoworkspace, 0"
          ## pyperland
          "$MOD SHIFT, Z, exec, pypr zoom"
          "$MOD ALT, P,exec, pypr toggle_dpms"
          "$MOD SHIFT, O, exec, pypr shift_monitors +1"
          "$MOD, B, exec, pypr expose"
          "$MOD, K, exec, pypr change_workspace +1"
          "$MOD, J, exec, pypr change_workspace -1"
          "$MOD,A,exec,pypr toggle term"
          "$MOD,V,exec,pypr toggle volume"
        ];
        
        binde = [
          ", XF86AudioLowerVolume, exec, ${pkgs.pamixer}/bin/pamixer -d 1"
          ", XF86AudioRaiseVolume, exec, ${pkgs.pamixer}/bin/pamixer -i 1"
          ", XF86AudioMute, exec, ${pkgs.pamixer}/bin/pamixer -t"
          ", XF86MonBrightnessUp, exec, ${pkgs.brightnessctl}/bin/brightnessctl s +1%"
          ", XF86MonBrightnessDown, exec, ${pkgs.brightnessctl}/bin/brightnessctl s 1%-"
        ];
        bindm = [
          # Move/resize windows with mainMod + LMB/RMB and dragging
          "$MOD, mouse:272, movewindow"
          "$MOD, mouse:273, resizewindow"
        ];
        bindl = [];
      };
    };
  };
}
