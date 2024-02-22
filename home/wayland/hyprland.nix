{ config, pkgs, lib, inputs, ... }: let
  col_active_border1 = "5e81acee";
  col_active_border2 = "81a1c1ee";
  col_inactive_border = "4c566aaa";

  # Monitors
  monitors = ["DP-3,2560x1440,0x0,1"];
in {
  config = {
    home.packages = [
      pkgs.killall
      # Audio Control
      pkgs.pavucontrol
      pkgs.swww
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
        env = [
          "XCURSOR_SIZE,24"
        ];
        monitor = monitors ++ [
          ",preferred,auto,auto"
        ];
        exec-once = [
          "waybar"
          "${pkgs.swww}/bin/swww init"
          "${pkgs.networkmanagerapplet}/bin/nm-applet"
          "[workspace 1 silent] $terminal"
        ];
        general = {
          gaps_in = 5;
          gaps_out = 5;
          border_size = 2;
          layout = "master";
          allow_tearing = false;
        };
        input = {
          kb_layout = "us";
          follow_mouse = 2;
          touchpad = {
            natural_scroll = "no";
          };
          sensitivity = 0;
        };
        decoration = {
          rounding = 10;
          blur = {
            enabled = true;
            size = 5;
            passes = 2;
          };
          drop_shadow = "no";
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
        master = {
          new_is_master = true;
          orientation = "top";
        };
        gestures.workspace_swipe = "off";
        misc = {
          # Anime lady hehe
          # force_default_wallpaper = -1;
          enable_swallow = true;
          swallow_regex = [
            "^(Alacritty)$"
          ];
        };
        "device:at-translated-set-2-keyboard" = {
          kb_options = "ctrl:nocaps";
        };
        windowrulev2 = [
          "nomaximizerequest, class:.*"
          
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
          "$MOD_SHIFT, Return, exec, $terminal"
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
          "$MOD, Return, layoutmsg, swapwithmaster"
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
        
          # Move active window to a workspace with mainMod + SHIFT + [0-9]
          "$MOD SHIFT, 1, movetoworkspace, 1"
          "$MOD SHIFT, 2, movetoworkspace, 2"
          "$MOD SHIFT, 3, movetoworkspace, 3"
          "$MOD SHIFT, 4, movetoworkspace, 4"
          "$MOD SHIFT, 5, movetoworkspace, 5"
          "$MOD SHIFT, 6, movetoworkspace, 6"
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
      };
    };
  };
}
