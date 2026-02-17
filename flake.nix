{
  description = "NIXOS FLAKE";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";

    # pinned to 6.18.4 - NVIDIA 580.x doesn't support 6.19 yet
    # to update: change rev to a newer commit from https://github.com/xddxdd/nix-cachyos-kernel/commits/release
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel?rev=ab815ddf2e7602f06451a1f723900afcf9ff7241";

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

        # pin cinnamon to stable
        ({ pkgs, ... }: let
          stablePkgs = nixpkgs-stable.legacyPackages.${pkgs.system};
          cinnamonNames = builtins.filter
            (name: builtins.substring 0 8 name == "cinnamon")
            (builtins.attrNames stablePkgs);
          cinnamonPkgs = builtins.listToAttrs (
            map (name: { inherit name; value = stablePkgs.${name}; }) cinnamonNames
          );
        in {
          nixpkgs.overlays = [
            (final: prev: cinnamonPkgs // {
              mint-y-icons = stablePkgs.mint-y-icons;
            })
          ];
        })
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
