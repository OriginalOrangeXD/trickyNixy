{
  description = "Basic Neovim Flake";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
    in
    {
      # Define the Neovim package
      devEnv = pkgs.mkShell {
        buildInputs = [ pkgs.neovim ];
        shellHook = ''
          # Configure Neovim options
          export XDG_CONFIG_HOME=$HOME/.config/nvim
          export XDG_DATA_HOME=$HOME/.local/share/nvim
          export XDG_CACHE_HOME=$HOME/.cache/nvim

          # Set Neovim as default editor
          export EDITOR=nvim
          export VISUAL=nvim
        '';
      };
    }
  );
}

