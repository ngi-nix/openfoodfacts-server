{
  description =
    "Open Food Facts is a food products database made by everyone, for everyone.";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

  # Upstream source tree(s).
  inputs.openfoodfacts-server-src = {
    url = ./.;
    flake = false;
  };

  outputs = { self, nixpkgs, openfoodfacts-server-src }:
    let

      # Generate a user-friendly version numer.
      version =
        builtins.substring 0 8 openfoodfacts-server-src.lastModifiedDate;

      # System types to support.
      supportedSystems = [ "x86_64-linux" ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems (system: f system);

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system:
        import nixpkgs {
          inherit system;
          overlays = [ self.overlay ];
        });

    in {

      # A Nixpkgs overlay.
      overlay = final: prev: {

        openfoodfacts-server = with final;
          stdenv.mkDerivation rec {
            name = "openfoodfacts-server-${version}";

            src = openfoodfacts-server-src;

            buildInputs = [ ];

            meta = {
              homepage = "https://world.openfoodfacts.org/";
              description = "A program to show a familiar, friendly greeting";
            };
          };

      };

      # Provide some binary packages for selected system types.
      packages = forAllSystems
        (system: { inherit (nixpkgsFor.${system}) openfoodfacts-server; });

      # The default package for 'nix build'. This makes sense if the
      # flake provides only one package or there is a clear "main"
      # package.
      defaultPackage =
        forAllSystems (system: self.packages.${system}.openfoodfacts-server);

      # A NixOS module, if applicable (e.g. if the package provides a system service).
      nixosModules.openfoodfacts-server = { pkgs, ... }: {
        nixpkgs.overlays = [ self.overlay ];

        environment.systemPackages = [ pkgs.openfoodfacts-server ];

        #systemd.services = { ... };
      };

    };
}
