{
  description = "My sexy OS ;>";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, self, nixpkgs, home-manager, ... }:
    let
      systems = import ./system { inherit inputs; };
    in 
      flake-parts.lib.mkFlake { inherit inputs; } {
	    systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ];
	    perSystem = { config, self', inputs', pkgs, system, ... }: {
		    packages = {
			    ruxy-nvim = pkgs.vimUtils.buildVimPlugin {
				    name = "ruxy";
				    src = ./config/nvim;
		            };
		    };
	    };
      flake = {
      nixosConfigurations = {
	ruxyDesk = systems.mkNixOS {
	  desktop = true;
          system = "x86_64";
          username = "ruxy";
	};
      };
    };
  };
}
