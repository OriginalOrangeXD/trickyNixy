{ inputs }:

{ desktop, system, username }:

let 
  desktop-conf = import ./hardware/desktop.nix;
  laptop-conf  = import ./hardware/laptop.nix;
in 
inputs.nixpkgs.lib.nixosSystem {
	inherit system;
	modules = [ 
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
			(import ./deskConfig.nix { inherit desktop username; })
	] else [ 
		(import ./hardware/laptop.nix)
		(import ./lapConfig.nix { inherit desktop username; })
	]);
}
