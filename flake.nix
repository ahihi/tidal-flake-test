{
  description = "flake to test consuming the Tidal flake ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    
    darwin.url = "github:lnl7/nix-darwin/nix-darwin-24.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    tidal.url = "github:tidalcycles/Tidal";
    tidal.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, tidal }: let
    tidalSystem = system:
      {
        system = system;
        modules = [
          {
            system.stateVersion = 5;
            nixpkgs.overlays =
              [
                (final: prev:
                  let
                    tidal-ghc = final.haskellPackages.ghcWithPackages
                      (p: [
                        tidal.packages.${system}.tidal
                      ]);
                  in
                    {
                      tidal-ghc = tidal-ghc;
                      tidal-ghci = final.writeShellScriptBin "tidal-ghci" ''
                        ${tidal-ghc}/bin/ghci
                      '';
                    }
                )
              ];
          }
          ({ pkgs, config, ... }:
            {
              environment.systemPackages = [
                pkgs.tidal-ghci
              ];
            }
          )
        ];
      };
  in
    {
      darwinConfigurations = {
        "darwinExample" = darwin.lib.darwinSystem (tidalSystem "x86_64-darwin");
      };
      nixosConfigurations = {
        "nixosExample" = nixpkgs.lib.nixosSystem (tidalSystem "x86_64-linux");
      };
    };
}
