{
  description =
    "Open Food Facts is a food products database made by everyone, for everyone";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05"; # PerlMagick Not Building
  # inputs.nixpkgs.url = "path:/home/thomassdk/summer-of-nix/nixpkgs";

  inputs.openfoodfacts-server-src = {
    url = "github:ngi-nix/openfoodfacts-server";
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

      perlWithModules = pkgs:
        pkgs.perl.withPackages (pp:
          with pkgs.perlPackages; [
            mod_perl2
            GraphViz2 # Tests are failing but module is building correctly
            CGI
            TieIxHash
            LWPUserAgent
            PerlMagick # Called ImageMagick in unstable, not building in 20.09
            MIMELite
            CacheMemcachedFast
            JSON
            JSONPP
            Clone
            CryptPasswdMD5
            EncodeDetect
            XMLSimple
            XMLFeedPP
            libapreq2
            DigestMD5File
            TimeLocal
            TemplateToolkit
            URIEscapeXS
            URIFind
            MathRandomSecure
            EmailStuffer
            FileCopyRecursive
            ListMoreUtils
            PodSimple
            GeoIP2
            EmailValid
            DateTime
            DateTimeLocale
            DateTimeFormatISO8601
            CryptScryptKDF
            LocaleMaketextLexicon
            ModernPerl
            TextCSV
            JSONParse
            Mojolicious
            Minion
            MojoPg
            LogAny
            LogLog4perl
            LogAnyAdapterLog4perl

            XMLEncoding
            GraphicsColor
            BarcodeZBar
            experimental
            ExcelWriterXLSX
            MongoDB
            EncodePunycode
            AlgorithmCheckDigits
            ImageOCRTesseract
            CLDRNumber
            DataDumperAutoEncode
            XMLRules
            TextFuzzy
            SpreadsheetCSV
            FilechmodRecursive
            DevelSize
            JSONCreate
            ActionCircuitBreaker
            ActionRetry
            LocaleMaketextLexiconGetcontext

            ### Test ###
            TestSimple13
            TestNumberDelta
            LogAnyAdapterTAP

            ### Develop ###
            PerlCritic
            TermReadLineGnu
            ApacheDB
          ]);

    in {
      # Nixpkgs overlays.
      overlay = final: prev: {

        product-opener = let perl = perlWithModules final;
        in final.stdenv.mkDerivation {
          name = "product-opener";
          src = self;
          buildInputs = [ perl ];
          installPhase = ''
            mkdir -p $out/ProductOpener

            cp lib/startup_apache2.pl $out
            cp scripts/build_lang.pl $out
            cp docker/backend-dev/scripts/* $out
            patchShebangs $out/

            cp lib/ProductOpener/* $out/ProductOpener
            cp docker/backend-dev/conf/Config* $out/ProductOpener
          '';
        };

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

      # Provide some binary packages for selected system types.
      packages = forAllSystems
        (system: { inherit (nixpkgsFor.${system}) product-opener; });

      devShell = forAllSystems (system:
        let inherit (nixpkgsFor.${system}) mkShell nix-generate-from-cpan;
        in mkShell { buildInputs = [ nix-generate-from-cpan ]; });

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
