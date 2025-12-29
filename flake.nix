{
  description = "NIXOS FLAKE";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, ...}@inputs: {
    nixosConfigurations.salad = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./configuration.nix

        # home-manager nixos module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.salad = import ./home.nix;
        }

        # pin cinnamon to stable
        ({ pkgs, ... }: {
          nixpkgs.config.packageOverrides = pkgs: {
            cinnamon = nixpkgs-stable.legacyPackages.${pkgs.system}.cinnamon;
            mint-y-icons = nixpkgs-stable.legacyPackages.${pkgs.system}.mint-y-icons;
          };
        })
      ];
    };
  };
}
