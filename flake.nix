{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-config = {
      url = "github:junglerobba/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      home-config = inputs.home-config.packages.${system}.module {
        username = "j";
        homedir = "/home";
      };
    in {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {

        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
          inputs.home-manager.nixosModules.default
          {
            home-manager = home-config // {
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
        ];
      };
    };
}
