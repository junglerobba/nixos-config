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
    };
    helix = {
      url = "github:helix-editor/helix";
    };
    home-config = {
      url = "github:junglerobba/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.tms.follows = "tms";
      inputs.helix.follows = "helix";
    };
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
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
          {
            nix.settings = {
              substituters = [
                "https://helix.cachix.org"
                "https://cosmic.cachix.org/"
              ];
              trusted-public-keys = [
                "helix.cachix.org-1:ejp9KQpR1FBI2onstMQ34yogDm4OgU2ru6lIwPvuCVs="
                "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE="
              ];
            };
          }
          ./configuration.nix
          inputs.nixos-cosmic.nixosModules.default
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
