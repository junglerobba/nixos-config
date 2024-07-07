{
  description = "Nixos config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tms = {
      url = "github:jrmoulton/tmux-sessionizer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    helix = {
      url = "github:helix-editor/helix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-config = {
      url = "github:junglerobba/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.tms.follows = "tms";
      inputs.helix.follows = "helix";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";
      desktop = "gnome";
      username = "junglerobba";
      home-config = inputs.home-config.packages.${system}.module {
        inherit username desktop;
        homedir = "/home/${username}";
      };
    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs desktop username;
        };
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
