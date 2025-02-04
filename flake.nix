{
  description = "flake to test consuming the Tidal flake ";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
    
    darwin.url = "github:lnl7/nix-darwin/nix-darwin-24.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";

    tidal.url = "github:tidalcycles/Tidal";
    tidal.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, tidal }:
    let
      tidalOverlay = final: prev:
        let
          system = prev.stdenv.hostPlatform.system;
        in
          tidal.packages.${system};
      tidalModule = system: { config, pkgs, ... }:
        {
          nixpkgs.overlays = [ tidalOverlay ];
          environment.systemPackages = [ pkgs.tidal-ghci ];
        };
    in
      {
        darwinConfigurations = {
          "darwinExample" = darwin.lib.darwinSystem rec {
            system = "x86_64-darwin";
            modules = [
              (tidalModule system)
              # make darwin-rebuild happy
              {
                system.stateVersion = 5;
              }
            ];
          };
        };
        nixosConfigurations = {
          "nixosExample" = nixpkgs.lib.nixosSystem rec {
            system = "x86_64-linux";
            modules = [
              (tidalModule system)
              # make nixos-rebuild happy
              {
                system.stateVersion = "24.11";
                boot.loader.grub.enable = true;
                boot.loader.grub.device = "/dev/sda";
              }
              ./nixosExample-hardware-configuration.nix
            ];
          };
        };
        overlays.default = tidalOverlay;
        packages = tidal.packages;
      };
}
