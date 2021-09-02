{
  description =
    "Open Food Facts is a food products database made by everyone, for everyone";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

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

      perlWithModules = { pkgs, test ? false, develop ? false }:
        let
          base = with pkgs.perlPackages; [
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
          testMods = with pkgs.perlPackages; [
            TestSimple13
            TestNumberDelta
            LogAnyAdapterTAP
          ];

          developMods = with pkgs.perlPackages; [
            PerlCritic
            TermReadLineGnu
            TermReadKey
            ApacheDB
          ];
        in pkgs.perl.withPackages (pp:
          base ++ (if test then testMods else [ ])
          ++ (if develop then developMods else [ ]));
    in {
      # Nixpkgs overlays.
      overlay = final: prev: {

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

        # taken from https://github.com/nix-community/docker-nixpkgs/blob/master/overlay.nix
        gitReallyMinimal = (final.git.override {
          perlSupport = false;
          pythonSupport = false;
          withManual = false;
          withpcre2 = false;
        }).overrideAttrs (_: {
          # installCheck is broken when perl is disabled
          doInstallCheck = false;
        });
      };

      devShell = forAllSystems (system:
        let inherit (nixpkgsFor.${system}) mkShell nix-generate-from-cpan;
        in mkShell { buildInputs = [ nix-generate-from-cpan ]; });

      defaultApp = forAllSystems (system: self.apps.${system}.runProject);

      apps = forAllSystems (system: {
        loadImages = let pkgs = nixpkgsFor.${system};
        in {
          type = "app";
          program = "${pkgs.writeShellScript "load images" ''
            IMAGES="${
              builtins.toString (builtins.attrValues self.dockerImages)
            }"
            for image in $IMAGES
            do
              docker load < $image
            done

            # Put this behind a flag?
            # Need this to be more specific
            docker system prune -f
          ''}";
        };

        runProject = let pkgs = nixpkgsFor.${system};
        in {
          type = "app";
          program = "${pkgs.writeShellScript "project up" ''
            # need to patch the docker-compose files to use the dockerImage outputs
            # and then run docker/start_dev.sh
          ''}";
        };
      });

      dockerImages = let
        pkgs = nixpkgsFor.x86_64-linux;
        apachePort = "80";
        inherit (pkgs)
          apacheHttpd busybox cacert dockerTools gitReallyMinimal gnumeric
          iproute2 lsb-release procps release wget;
        perlRunnable = perlWithModules { inherit pkgs; };
        perlDebug = perlWithModules {
          inherit pkgs;
          test = true;
          develop = true;
        };
        config = {
          WorkingDir = "/opt/product-opener";
          ExposedPorts = { "${apachePort}/tcp" = { }; };
        };
      in {
        base = dockerTools.buildImage {
          name = "base";
          tag = "latest";
          contents = [ apacheHttpd busybox cacert gnumeric wget ];
          runAsRoot = ''
            #!${pkgs.runtimeShell}
            touch /etc/passwd
            ${dockerTools.shadowSetup}

            adduser -H -D www-run
            addgroup www-run www-run

            mkdir -p /opt/product-opener
            # Should this be a symlink?
            cp -r ${openfoodfacts-server-src}/* /opt/product-opener/
          '';
        };

        runnable = dockerTools.buildLayeredImage {
          fromImage = self.dockerImages.base;
          name = "runnable";
          tag = "latest";
          contents = [ perlRunnable ];
          inherit config;
        };

        debug = dockerTools.buildLayeredImage {
          name = "debug";
          tag = "latest";
          fromImage = self.dockerImages.base;
          contents = [ perlDebug ];
          inherit config;
        };

        # TODO: Base off of this:
        # https://github.com/nix-community/docker-nixpkgs/blob/master/images/devcontainer/default.nix
        vscode = dockerTools.buildLayeredImage {
          name = "vscode";
          tag = "latest";
          # NOTE: Error: usedLayers 101 layers to store 'fromImage' and 'extraCommands',
          # but only maxLayers=100 were allowed.
          # At least 1 layer is required to store contents.
          maxLayers = 102;
          fromImage = self.dockerImages.debug;
          contents = [ gitReallyMinimal iproute2 procps lsb-release ];
          # config = {

          # } // config;
        };
      };
    };
}
