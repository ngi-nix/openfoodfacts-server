{
  description =
    "Open Food Facts is a food products database made by everyone, for everyone";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05"; # PerlMagick Not Building
  inputs.unstable.url =
    "nixpkgs/nixos-unstable"; # Perl is no longer split so Perl530 becomes Perl, modPerl package is broken

  # Upstream source tree(s).
  inputs.openfoodfacts-server-src = {
    url = "path:../.";
    flake = false;
  };

  outputs = { self, nixpkgs, unstable, openfoodfacts-server-src }:
    let
      # Generate a user-friendly version numer.
      version = "0.0.1";
      # builtins.substring 0 8 openfoodfacts-server-src.lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system:
        import unstable {
          inherit system;
          overlays = nixpkgs.lib.attrValues self.overlays;
        });

    in {

      # Nixpkgs overlays.
      overlays = {
        openfoodfacts-server-backend = final: prev: {
          openfoodfacts-server-backend =
            final.callPackage ./server-backend.nix {
              src = openfoodfacts-server-src;
              inherit version;
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
          } // final.callPackage ./localPerlPackages.nix { };
        };
      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) openfoodfacts-server-backend;
      });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage = forAllSystems
        (system: self.packages.${system}.openfoodfacts-server-backend);

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      # nixosModules.openfoodfacts-server = { pkgs, ... }: {
      #   nixpkgs.overlays = [ self.overlay ];

      #   environment.systemPackages = [ pkgs.openfoodfacts-server ];

      #   #systemd.services = { ... };
      # };

    };
}
