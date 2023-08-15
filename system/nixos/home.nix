{ desktop, inputs }:

{ config, pkgs, ... }:

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "ruxy";
  home.homeDirectory = "/home/ruxy";
  home.stateVersion = "23.05"; 

  imports = if desktop then [ ./deskHome.nix ] else [ ./lapHome.nix ];

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
  programs.tmux = {
    enable = true;
    extraConfig = ''
      set-option -a terminal-overrides ",*256col*:RGB"
    '';
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "xterm-256color";
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
      vimPlugins.rust-tools-nvim
      vimPlugins.clangd_extensions-nvim

      # telescope
      vimPlugins.plenary-nvim
      vimPlugins.popup-nvim
      vimPlugins.telescope-nvim

      # theme
      vimPlugins.catppuccin-nvim

      # floaterm
      vimPlugins.vim-floaterm
      
      # PRIME
      vimPlugins.harpoon

      vimPlugins.lsp-zero-nvim
      vimPlugins.nvim-cmp
      vimPlugins.cmp-nvim-lsp

      arduino-language-server
      lua-language-server

      # extras
      (vimPlugins.ChatGPT-nvim.overrideAttrs (old: {
        src = fetchFromGitHub {
          owner = "jackMort";
          repo = "ChatGPT.nvim";
          rev = "f499559f636676498692a2f19e74b077cbf52839";
          sha256 = "sha256-98daaRkdrTZyNZuQPciaeRNuzyS52bsha4yyyAALcog=";
        };
      }))
      vimPlugins.copilot-lua
      vimPlugins.gitsigns-nvim
      vimPlugins.lualine-nvim
      vimPlugins.nerdcommenter
      vimPlugins.noice-nvim
      vimPlugins.nui-nvim
      vimPlugins.nvim-colorizer-lua
      vimPlugins.nvim-notify
      vimPlugins.nvim-treesitter-context
      vimPlugins.nvim-ts-rainbow2
      #vimPlugins.nvim-web-devicons # https://github.com/intel/intel-one-mono/issues/9

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
      python310Full
      rustc

      # language servers
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
      python310Packages.black
      rustfmt

      # tools
      cargo
      gcc
      ghc
      lazydocker
      yarn
    ];
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
