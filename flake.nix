{
  description = "NIXOS FLAKE";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, ...}@inputs: {
    nixosConfigurations.salad = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./configuration.nix
        # inputs.home-manager.nixosModules.default

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
