{ inputs }:

{ desktop, system, username }:

let 
  desktop-conf = import ./hardware/desktop.nix;
  laptop-conf  = import ./hardware/laptop.nix;
  configuration = import ./configuration.nix { inherit desktop username; };
in 
inputs.nixpkgs.lib.nixosSystem {
	inherit system;
	modules = [ 
		configuration
		inputs.home-manager.nixosModules.home-manager
		{
			home-manager.useGlobalPkgs = true;
			home-manager.useUserPackages = true;
			home-manager.users.ruxy = import ./home.nix {
				inherit desktop inputs;
			};
		}
	]++ (if desktop then [
			(import ./hardware/desktop.nix)
	] else [ 
		(import ./hardware/laptop.nix)
	]);
}
