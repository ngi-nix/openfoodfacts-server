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
        let
          pkgs = (nixpkgsFor.${system});
          perl = perlWithModules {
            inherit pkgs;
            test = true;
            develop = true;
          };
          inherit (pkgs) mkShell nix-generate-from-cpan nodejs nodePackages;
        in mkShell {
          buildInputs = [ nix-generate-from-cpan nodejs nodePackages.npm perl ];
        });

      defaultApp = forAllSystems (system: self.apps.${system}.runProject);

      apps = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          # node-gyp requires python make and a c/c++ compiler
          inherit (pkgs)
            writeShellScript nodejs nodePackages python39 gnumake gcc;
          npm = "${nodePackages.npm}/bin/npm";
          nodeScript = name: commands: {
            type = "app";
            program = "${writeShellScript "${name}" ''
              export PATH=$PATH:${nodejs}/bin:${nodePackages.npm}/bin:${python39}/bin:${gnumake}/bin:${gcc}/bin
              ${npm} install
              ${commands}
            ''}";
          };
        in {
          runProject = {
            type = "app";
            program = "${writeShellScript "project up" ''
              # need to patch the docker-compose files to use the dockerImage outputs
              # and then run docker/start_dev.sh with the docker-compose patched to ${pkgs.docker-compose}
              # will this work with permissions?
            ''}";
          };

          loadImages = {
            type = "app";
            program = "${writeShellScript "load images" ''
              IMAGES="${
                builtins.toString (builtins.attrValues self.dockerImages)
              }"
              for image in $IMAGES
              do
                ${pkgs.docker} load < $image
              done

              # Put this behind a flag?
              # Need this to be more specific
              ${pkgs.docker} system prune -f
            ''}";
          };

          buildFrontEnd = nodeScript "Build FrontEnd Assets" "${npm} run build";

          watchFrontEnd =
            nodeScript "Watch FrontEnd Assets" "${npm} run build:watch";

        });

      dockerImages = let
        pkgs = nixpkgsFor.x86_64-linux;
        tag = "latest";
        inherit (pkgs) dockerTools;
        config = { WorkingDir = "/opt/product-opener"; };
      in {
        backend-base =
          let inherit (pkgs) apacheHttpd busybox cacert gnumeric wget;
          in dockerTools.buildImage {
            name = "backend-base";
            inherit tag;
            contents = [ apacheHttpd busybox cacert gnumeric wget ];
            runAsRoot = ''
              #!${pkgs.runtimeShell}
              ${dockerTools.shadowSetup}

              adduser -H -D www-data
              addgroup www-data www-data

              # src uses apache2ctl in po-foreground.sh
              # TODO: Patch
              ln -s /bin/apachectl /bin/apache2ctl

              mkdir -p /etc/httpd
              ln -s ${apacheHttpd}/conf/httpd.conf /etc/httpd/

              mkdir -p /opt/product-opener
              cp -r ${self}/* /opt/product-opener/
            '';
          };

        backend-runnable = let perl = perlWithModules { inherit pkgs; };
        in dockerTools.buildLayeredImage {
          fromImage = self.dockerImages.backend-base;
          inherit tag config;
          name = "runnable";
          contents = [ perl ];
        };

        backend-test = let
          perl = perlWithModules {
            inherit pkgs;
            test = true;
            develop = true;
          };
        in dockerTools.buildLayeredImage {
          name = "test";
          inherit tag config;
          fromImage = self.dockerImages.backend-base;
          contents = [ perl ];
        };

        # TODO: Base off of this:
        # https://github.com/nix-community/docker-nixpkgs/blob/master/images/devcontainer/default.nix
        backend-vscode =
          let inherit (pkgs) gitReallyMinimal iproute2 procps lsb-release;
          in dockerTools.buildLayeredImage {
            name = "vscode";
            inherit tag config;
            # NOTE: Error: usedLayers 101 layers to store 'fromImage' and 'extraCommands',
            # but only maxLayers=100 were allowed.
            # At least 1 layer is required to store contents.
            maxLayers = 102;
            fromImage = self.dockerImages.backend-test;
            contents = [ gitReallyMinimal iproute2 procps lsb-release ];
            # config = {

            # } // config;
          };

        # Is this necessary of should is it better to use something like hocker?
        # https://github.com/awakesecurity/hocker
        frontend = let inherit (pkgs) nginx;
        in dockerTools.buildImage {
          name = "frontend";
          inherit tag;
          contents = [ nginx ];
        };
      };
    };
}
