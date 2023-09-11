{ inputs }:

{ desktop, system, username }:

let 
  default-conf = import ./defaultConfig.nix;
in 
inputs.nixpkgs.lib.nixosSystem {
	inherit system;
	modules = [ 
        default-conf
		inputs.home-manager.nixosModules.home-manager
		{
			home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
			home-manager.users.ruxy = import ./home.nix {
				inherit desktop inputs;
			};
		}
	] ++ (if desktop then [
			(import ./hardware/desktop.nix)
            (import ./python.nix)
			(import ./deskConfig.nix { inherit desktop username; })
	] else [ 
        (import ./python.nix)
		(import ./hardware/laptop.nix)
		(import ./lapConfig.nix { inherit desktop username; })
	]);
}
