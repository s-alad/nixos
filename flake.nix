{
  description = "NIXOS FLAKE";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, ...}@inputs: {
    nixosConfigurations.salad = nixpkgs.lib.nixosSystem {
      specialArgs = {inherit inputs;};
      modules = [
        ./hosts/salad/configuration.nix

        # CachyOS kernel overlay + selection + cache
        ({ pkgs, ... }: {
          nixpkgs.overlays = [
            inputs.nix-cachyos-kernel.overlays.pinned

            # pin linux-firmware to stable to avoid issues with iwlwifi crashes
            (final: prev: {
              linux-firmware = nixpkgs-stable.legacyPackages.${prev.system}.linux-firmware;
            })
          ];

          nix.settings.substituters = [ "https://attic.xuyh0120.win/lantian" ];
          nix.settings.trusted-public-keys =
            [ "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=" ];
        })

        # home-manager nixos module
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.salad = import ./home/salad.nix;
          home-manager.backupFileExtension = "backup";
        }

        # cinnamon - using unstable (no pin)
      ];
    };

    # --- standalone home-manager for macOS work laptop (aarch64-darwin)
    homeConfigurations."datadog" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.aarch64-darwin;
      modules = [
        ./home/datadog.nix
      ];
    };
  };
}
