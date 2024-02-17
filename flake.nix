{
  description = "My sexy OS ;>";

  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    lib-aggregate = {
      url = "github:nix-community/lib-aggregate";
    };
    nixpkgs-stable = {
      url = "github:nixos/nixpkgs/nixos-23.11";
    }; 
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
    };
  };

  outputs = 
    inputs:
    let
      defaultSystems = [
        "x86_64-linux"
      ];

      lib = inputs.lib-aggregate.lib;

      importPkgs =
        npkgs: extraCfg:
        (lib.genAttrs defaultSystems (
          system:
          import npkgs {
            inherit system;
            config =
              let
                cfg = ({ allowAliases = false; } // extraCfg);
              in
                cfg;
          }
        ));
      pkgs = importPkgs inputs.nixpkgs-stable { };
      pkgsUnfree = importPkgs inputs.nixpkgs-stable { allowUnfree = true; };

      mkSystem =
        n: v:
        (v.pkgs.lib.nixosSystem {
          modules =
            [ (v.path or (./hosts/${n}/configuration.nix)) ]
            ++ (
              if (!builtins.hasAttr "buildSys" v) then
                [ ]
              else
                [ { config.nixpkgs.buildPlatform.system = v.buildSys; } ]
            );
          specialArgs = {
            inherit inputs;
          };
        });
      nixosConfigsEx = {
        "x86_64-linux" = rec {
          ruxyDesk = {
            pkgs = inputs.pkgsUnfree;
          };
        };
      };
      nixosConfigs = (lib.foldl' (op: nul: nul // op) { } (lib.attrValues nixosConfigsEx));
      nixosConfigurations = (lib.mapAttrs (n: v: (mkSystem n v)) nixosConfigs);
      toplevels = (lib.mapAttrs (_: v: v.config.system.build.toplevel) nixosConfigurations);
  in 
  lib.recursivetUpdate
    ({
      inherit
        nixosConfigs
        nixosConfigsEx
        nixosConfigurations
        toplevels
        ;
      # inherit nixosModules overlays;
      inherit pkgs pkgsUnfree;
    })
    (
      lib.flake-utils.eachSystem defaultSystems (
        system:
        let
          mkShell = (
            name:
            import ./shells/${name}.nix {
              inherit inputs;
              pkgs = pkgs.${system};
            }
          );
          mkAppScript = (
            name: script: {
              type = "app";
              program = (pkgs.${system}.writeScript "${name}.sh" script).outPath;
            }
          );
        in
        rec {
          devShells =
            (lib.flip lib.genAttrs mkShell [
              "ci"
              "dev"
              "uutils"
            ])
            // {
              default = devShells.ci;
            };
          homeConfigurations = (
            lib.genAttrs [ "env-ci" ] (
              h:
              inputs.home-manager.lib.homeManagerConfiguration {
                pkgs = pkgs.${system};
                modules = [ ./hm/${h}.hix ];
                extraSpecialArgs = {
                  inherit inputs;
                };
              }
            )
          );
          tophomes = (lib.mapAttrs (_: v: v.activation-script) homeConfigurations);
        }
      )
    );
}
