{
  description =
    "Open Food Facts is a food products database made by everyone, for everyone";


  inputs = {
    nixpkgs.url = "nixpkgs/nixos-21.05";
    arion.url = "github:hercules-ci/arion";

    npmlock2nix = {
      url = "github:nix-community/npmlock2nix";
      flake = false;
    };

    openfoodfacts-server-src = {
      url = "github:ngi-nix/openfoodfacts-server";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, openfoodfacts-server-src, ... }@inputs:
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

      perl4project = { pkgs }:
        let
          baseModules = with pkgs.perlPackages; [
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
          ];
          testModules = with pkgs.perlPackages; [
            TestSimple13
            TestNumberDelta
            LogAnyAdapterTAP
          ];
          developModules = with pkgs.perlPackages; [
            PerlCritic
            TermReadLineGnu
            TermReadKey
            ApacheDB
          ];
        in {
          base = pkgs.perl.withPackages (pp: baseModules);
          test = pkgs.perl.withPackages (pp: baseModules ++ testModules);
          develop = pkgs.perl.withPackages (pp: baseModules ++ developModules);
          complete = pkgs.perl.withPackages
            (pp: baseModules ++ testModules ++ developModules);
        };
    in {
      # Nixpkgs overlays.
      overlay = final: prev: {

        perlWithModules = perl4project { pkgs = final; };

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

        npmlock2nix = prev.callPackage inputs.npmlock2nix { };

        inherit self;

        arion = inputs.arion.defaultPackage.${prev.system};

        project = inputs.arion.lib.build {
          modules = [ ./arion-compose.nix ];
          pkgs = final;
        };

        # node-gyp requires python make and a c/c++ compiler
        build_NodeModules = let
          inherit (final)
            npmlock2nix python39 gnumake gcc lib stdenv CoreServices xcodebuild;
        in npmlock2nix.node_modules {
          src = self;
          buildInputs = [ python39 gnumake gcc ]
            ++ lib.optionals (stdenv.isDarwin) [ CoreServices xcodebuild ];
          # this doesnt work as the package.json is symlinked from the store
          # patchPhase = [ ./0001-dont-run-snyk-protect-on-npm-install.patch ];
          # at the present this line has been deleted from the package.json
          preBuild = "cp ${openfoodfacts-server-src}/.snyk ./";
        };

        build_npm = let inherit (final) npmlock2nix python39 gnumake gcc;
        in npmlock2nix.build {
          src = self;
          installPhase = "cp -r html $out";
          node_modules_attrs = { buildInputs = [ python39 gnumake gcc ]; };
        };
      };

      # Needed to run arion
      legacyPackages.x86_64-linux = nixpkgsFor.x86_64-linux;

      packages = forAllSystems (system: {
        inherit (nixpkgsFor.${system}) build_NodeModules build_npm project;
      });

      defaultPackage = forAllSystems (system: self.packages.${system}.project);

      devShell = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          perl = pkgs.perlWithModules.complete;
          inherit (pkgs)
            mkShell nix-generate-from-cpan arion npmlock2nix python39 gnumake
            gcc;
          git = "${pkgs.git}/bin/git";
        in npmlock2nix.shell {
          src = self;
          buildInputs = [ nix-generate-from-cpan perl arion ];
          node_modules_attrs = { buildInputs = [ python39 gnumake gcc ]; };
          shellHook = ''
            alias clean="${git} clean -fxd --exclude=node_modules"
            alias watch="npm run build:watch"

            clean
            npm run snyk-protect

            # npmlock2nix builds the node_modules in a pure way
            # this builds the assets in an impure way so that gulp can
            # watch the files and update them during development
            # on deployment the npm assets will be built reproducibly by nix
            # based on the current commit
            npm run build
          '';
        });

      defaultApp = forAllSystems (system: self.apps.${system}.runProject);

      apps = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          inherit (pkgs) writeShellScript;
        in {
        });
    };
}
