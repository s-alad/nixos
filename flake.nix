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

  outputs = { self, nixpkgs, nixpkgs-stable, home-manager, ... }@inputs:
    let
      # ---- host configurations (system-specific; unchanged behavior) ----
      static = {
        nixosConfigurations.salad = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/salad/configuration.nix

            # CachyOS kernel overlay + selection + cache
            ({ pkgs, ... }: {
              nixpkgs.overlays = [
                inputs.nix-cachyos-kernel.overlays.pinned
              ] ++ (import ./overlays/failure.nix { inherit nixpkgs-stable; });

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

      # ---- dev outputs: formatter / checks / devShell ----
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-darwin" ];
    in
    static // {
      # `nix fmt` — canonical RFC-166 Nix formatter
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixfmt-rfc-style);

      # `nix develop` — shell for working on this config (tools pulled only when entered)
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system};
        in {
          default = pkgs.mkShellNoCC {
            packages = with pkgs; [ nh nixfmt-rfc-style nix-diff git ];
          };
        });

      # `nix flake check` — build each host's real output on its native system
      checks = {
        x86_64-linux.salad = self.nixosConfigurations.salad.config.system.build.toplevel;
        aarch64-darwin.datadog = self.homeConfigurations."datadog".activationPackage;
      };
    };
}
