{ config, pkgs,inputs, ... }:
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "robby";
  home.homeDirectory = "/home/robby";
  home.stateVersion = "24.11"; 
  imports = [
    ../../home
  ];

  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };
  programs.kitty = {
      enable = true;
      settings = {
	        font_family = "IosevkaTerm Nerd Font Mono";
          background_opacity = "0.8";
          font_size = "16";
	        enable_audio_bell="no";
      };
      themeFile = "gruvbox-dark";
  };
  programs.tmux = {
    enable = true;
    clock24 = true;
    extraConfig = ''
      unbind C-b
      set-option -g prefix C-v
      set-option -a terminal-overrides ",*256col*:RGB"
      setw -g mode-keys vi
      bind-key h select-pane -L
      bind-key j select-pane -D
      bind-key k select-pane -U
      bind-key l select-pane -R
      set -g mouse on

      set -g status-position top
      set -g @plugin 'olimorris/tmux-pomodoro-plus'
    '';
    shell = "${pkgs.zsh}/bin/zsh";

    plugins = with pkgs.tmuxPlugins; [
        sensible
        yank
        vim-tmux-navigator
        {
			plugin = gruvbox;
			extraConfig = ''
          set -g @tmux-gruvbox 'dark' # or 'light', 'dark-transparent', 'light-transparent'
			'';
		}
    ];
  };
    programs.zsh = {
    enable = true;
    autosuggestion.enable= true;
    enableCompletion = true;
    syntaxHighlighting = {
      enable = true;
    };

    oh-my-zsh = {
      enable = true;
      plugins = [ "git" ];
    };

    shellAliases = {
      cat = "bat";
      wt = "git worktree";
      vim = "nvim";
    };


  };

  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/ruxy/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  # home.file.".background-image".source = ../../config/background-image;
}
