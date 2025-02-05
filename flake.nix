{
  description = "My sexy OS ;>";

  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-unstable";
    }; 
    home-manager = {
      url = "github:nix-community/home-manager";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
    ruxy-nvim = {
      url = "github:OriginalOrangeXD/ruxy.nvim";
    };
    nix-matlab = {
      # nix-matlab's Nixpkgs input follows Nixpkgs' nixos-unstable branch. However
      # your Nixpkgs revision might not follow the same branch. You'd want to
      # match your Nixpkgs and nix-matlab to ensure fontconfig related
      # compatibility.
      inputs.nixpkgs.follows = "nixpkgs";
      url = "gitlab:doronbehar/nix-matlab";
    };
  # ...

  };

  outputs = { flake-parts,self, nixpkgs, nix-matlab, ... } @inputs:
    let 
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      flake-overlays = [
        nix-matlab.overlay
      ];

    in 
    flake-parts.lib.mkFlake { inherit inputs; } {
	systems = [ "aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux" ];
	flake = {
        nixosConfigurations = {
            acdc = nixpkgs.lib.nixosSystem {
                specialArgs = {inherit inputs;};
                modules = [
                    (import ./hosts/acdc/configuration.nix flake-overlays)
                    inputs.home-manager.nixosModules.default
                ];
            };
            frame = nixpkgs.lib.nixosSystem {
                specialArgs = {inherit inputs;};
                modules = [
                    (import ./hosts/frame/configuration.nix flake-overlays)
                    inputs.home-manager.nixosModules.default
                ];
            };
        };
    };
};
}
