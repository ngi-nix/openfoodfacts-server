{
  description =
    "Open Food Facts is a food products database made by everyone, for everyone";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05"; # PerlMagick Not Building

  outputs = { self, nixpkgs }:
    let
      zbar-src = nixpkgs.legacyPackages.x86_64-linux.zbar.src;
      openfoodfacts-server-src = self;

      # Generate a user-friendly version numer.
      version = builtins.substring 0 8 self.lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = nixpkgs.lib.attrValues self.overlays;
        });

    in {
      # Nixpkgs overlays.
      overlays = {
        product-opener = final: prev: {
          product-opener = final.stdenv.mkDerivation {
            name = "product-opener";
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p $out/ProductOpener
              cp ${self}/lib/ProductOpener/* $out/ProductOpener
              cp ${self}/docker/backend-dev/conf/Config* $out/ProductOpener
            '';
          };
        };

        perlPackages = final: prev: rec {
          perlPackages = prev.perlPackages.override {
            overrides = pkgs: {
              # JSON-Create requires JSONParse >= 0.60; nixpkgs version = 0.57
              JSONParse = (prev.perlPackages.JSONParse.overrideAttrs (_: rec {
                version = "0.61";
                src = prev.fetchurl {
                  url =
                    "mirror://cpan/authors/id/B/BK/BKB/JSON-Parse-0.61.tar.gz";
                  sha256 =
                    "ce8e55e70bef9bcbba2e96af631d10a605900961a22cad977e71aab56c3f2806";
                };
              }));
            };
          } // final.callPackage ./nix/localPerlPackages.nix { };
        };
      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems
        (system: { inherit (nixpkgsFor.${system}) product-opener; });

      devShell = forAllSystems (system:
        let pkgs = nixpkgsFor.${system};
        in with pkgs; mkShell { buildInputs = [ nix-generate-from-cpan ]; });

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      nixosModules = { server-backend = import ./nix/server-backend.nix; };

      nixosConfigurations.container = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        specialArgs = { src = openfoodfacts-server-src; };
        pkgs = nixpkgsFor.${system};
        modules = [
          self.nixosModules.server-backend

          ({ pkgs, ... }: {
            boot.isContainer = true;

            system.configurationRevision =
              nixpkgs.lib.mkIf (self ? rev) self.rev;

            services.openfoodfacts.enable = true;
          })
        ];
      };
    };
}
