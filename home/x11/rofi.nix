{ config, pkgs, lib, ... }:
{
  config = {
    home.packages = [ pkgs.nerdfonts pkgs.rofi-wayland ];
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland;
      font = "JetBrainsMono Nerd Font 12";
      extraConfig = {
        modi = "run,drun,window";
        drun-display-format = "{name}";
        # sidebar-mode = true;
        matching = "fuzzy";
        scroll-method = 0;
        disable-history = false;
        show-icons = true;

        display-drun = "Application";
        display-run = "Command";
        display-window = "Window";

        kb-mode-complete = "";
        kb-remove-to-eol = "";
        kb-remove-char-back = "BackSpace,Shift+BackSpace";
        kb-accept-entry = "Return,KP_Enter";
        kb-primary-paste = "Alt-v";
        kb-row-up = "Up,Control-k";
        kb-row-down = "Down,Control-j";
        kb-row-left = "Control-h";
        kb-row-right = "Control-l";
      };
      #theme = ~/.config/rofi/config.rasi;
    };
  };
}
