{
  description = "My sexy OS ;>";

  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-23.11";
    }; 
    home-manager = {
      url = "github:nix-community/home-manager";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
  };

  outputs = { self, nixpkgs, ... } @inputs:
    let 
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
    in 
    {
        nixosConfigurations = {
            acdc = nixpkgs.lib.nixosSystem {
                #extraSpecialArgs = {inherit inputs;};
                modules = [
                    ./nixos/acdc/configuration.nix
                ];
            };
            frame = nixpkgs.lib.nixosSystem {
                #extraSpecialArgs = {inherit inputs;};
                modules = [
                    ./nixos/frame/configuration.nix
                ];
            };
        };
    };
}
