{ config, pkgs,inputs, ... }:
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ruxy";
  home.homeDirectory = "/home/ruxy";
  home.stateVersion = "23.11"; 

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
	  font_family = "Agave Nerd Font Mono Regular";
          background_opacity = "0.9";
          font_size = "12";
	  enable_audio_bell="no";
      };
      theme = "Darkside";
  };
  programs.tmux = {
    enable = true;
    clock24 = true;
    extraConfig = ''
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
			plugin = dracula;
			extraConfig = ''
				set -g @dracula-show-battery false
				set -g @dracula-show-powerline true
                set -g @dracula-fixed-location "Based-City"
                set -g @dracula-show-fahrenheit false
				set -g @dracula-refresh-rate 10
			'';
		}
    ];
  };
    programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
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
  programs.neovim = {
      enable = true;

      plugins = with pkgs; [
      # languages
      vimPlugins.nvim-lspconfig
      vimPlugins.nvim-treesitter.withAllGrammars
      vimPlugins.nvim-treesitter-parsers.templ
      vimPlugins.rust-tools-nvim
      vimPlugins.clangd_extensions-nvim
      vimPlugins.vimtex

      # telescope
      vimPlugins.plenary-nvim
      vimPlugins.popup-nvim
      vimPlugins.telescope-nvim

      # theme
      vimPlugins.catppuccin-nvim
      vimPlugins.onedarkpro-nvim

      # floaterm
      vimPlugins.vim-floaterm
      
      # PRIME
      vimPlugins.harpoon

      vimPlugins.lsp-zero-nvim
      vimPlugins.nvim-cmp
      vimPlugins.cmp-nvim-lsp

      arduino-language-server
      lua-language-server

      vimPlugins.vim-tmux-navigator
      vimPlugins.gitsigns-nvim
      vimPlugins.lualine-nvim
      vimPlugins.nerdcommenter
      vimPlugins.noice-nvim
      vimPlugins.nui-nvim
      vimPlugins.nvim-colorizer-lua
      vimPlugins.nvim-notify
      vimPlugins.nvim-treesitter-context
      vimPlugins.rainbow-delimiters-nvim
      vimPlugins.omnisharp-extended-lsp-nvim
      #vimPlugins.nvim-web-devicons # https://github.com/intel/intel-one-mono/issues/9
      vimPlugins.mason-nvim
      vimPlugins.mason-lspconfig-nvim
      vimPlugins.nvim-cmp
      vimPlugins.cmp-nvim-lsp
      vimPlugins.luasnip
      vimPlugins.cmp_luasnip
      vimPlugins.nvchad


      # configuration
      inputs.self.packages.${pkgs.system}.ruxy-nvim
    ];

    extraConfig = ''
      lua << EOF
        require 'ruxy'.init()
      EOF
    '';

    extraPackages = with pkgs; [
      # languages
      jsonnet
      nodejs
      python312
      #python312Packages.pip
      rustc

      # language servers
      omnisharp-roslyn
      gopls
      haskell-language-server
      jsonnet-language-server
      lua-language-server
      nil
      nodePackages."bash-language-server"
      nodePackages."diagnostic-languageserver"
      nodePackages."dockerfile-language-server-nodejs"
      nodePackages."pyright"
      nodePackages."typescript"
      nodePackages."typescript-language-server"
      nodePackages."vscode-langservers-extracted"
      nodePackages."yaml-language-server"
      rust-analyzer
      terraform-ls

      # formatters
      gofumpt
      golines
      nixpkgs-fmt
      #python312Packages.black
      rustfmt

      # tools
      cargo
      gcc
      gcc_multi
      ghc
      lazydocker
      yarn
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.file.".background-image".source = ../../config/background-image;
}
