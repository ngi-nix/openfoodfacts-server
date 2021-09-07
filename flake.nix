{
  description =
    "Open Food Facts is a food products database made by everyone, for everyone";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-21.05";

  inputs.npmlock2nix-src = {
    url = "github:nix-community/npmlock2nix";
    flake = false;
  };

  inputs.openfoodfacts-server-src = {
    url = "github:ngi-nix/openfoodfacts-server";
    flake = false;
  };

  outputs = { self, nixpkgs, npmlock2nix-src, openfoodfacts-server-src }:
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

        npmlock2nix = prev.callPackage npmlock2nix-src { };

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

      packages = forAllSystems
        (system: { inherit (nixpkgsFor.${system}) node_modules build_npm; });

      defaultPackage =
        forAllSystems (system: self.packages.${system}.build_npm);

      devShell = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          perl = perlWithModules {
            inherit pkgs;
            test = true;
            develop = true;
          };
          inherit (pkgs)
            mkShell nix-generate-from-cpan npmlock2nix python39 gnumake gcc;
          git = "${pkgs.git}/bin/git";
        in npmlock2nix.shell {
          src = self;
          buildInputs = [ nix-generate-from-cpan perl ];
          node_modules_attrs = { buildInputs = [ python39 gnumake gcc ]; };
          shellHook = ''
            alias clean="${git} clean -fxd --exclude=node_modules"
            alias watch="npm run build:watch"

            clean
            npm run build
          '';
        });

      defaultApp = forAllSystems (system: self.apps.${system}.runProject);

      apps = forAllSystems (system:
        let
          pkgs = nixpkgsFor.${system};
          inherit (pkgs)
            writeShellScript nodejs nodePackages python39 gnumake gcc;
          docker = "${pkgs.docker}/bin/docker";
          docker-compose = "${pkgs.docker-compose}/bin/docker-compose";
          npm = "${nodePackages.npm}/bin/npm";
          nodeScript = name: commands: {
            type = "app";
            program = "${writeShellScript "${name}" ''
              export PATH=$PATH:${nodejs}/bin:${nodePackages.npm}/bin:${python39}/bin:${gnumake}/bin:${gcc}/bin
              ${npm} install
              # only need the gcc etc. for the inital install
              # export PATH=$PATH:${nodejs}/bin:${nodePackages.npm}/bin
              ${commands}
            ''}";
          };
        in {

          start_dev = {
            type = "app";
            program = "${writeShellScript "build dev environment" ''
              ${docker-compose} -f docker/docker-compose.yml -f docker/docker-compose.dev.yml up
            ''}";
          };

          build_dev = {
            type = "app";
            program = "${writeShellScript "load images" ''
              IMAGES="${
                builtins.toString (builtins.attrValues self.dockerImages)
              }"

              # Put this behind a flag?
              # Need this to be more specific
              # ${docker} system prune -f

              for image in $IMAGES
              do
                ${docker} load < $image
              done

            ''}";
          };

          # Need to restrict this to just the docker assets related to the project
          clean_docker = {
            type = "app";
            program = "${writeShellScript "remove all Docker assets" ''
              ${docker-compose} -f docker/docker-compose.yml -f docker/docker-compose.dev.yml down
              ${docker} container prune -f
              ${docker} volume prune -f
              ${docker} rmi $(docker images -q) -f
            ''}";
          };

          # This needs to go into a derviation that builds the assets and then
          # COPIES them over to the respective folders in the repo
          # Thus allowing the `watch_npm` script to function
          # Am I right in thinking that
          build_npm = nodeScript "Build FrontEnd Assets" "${npm} run build";

          watch_npm =
            nodeScript "Watch FrontEnd Assets" "${npm} run build:watch";

        });

      dockerImages = let
        pkgs = nixpkgsFor.x86_64-linux;
        inherit (pkgs) dockerTools;
        tag = null;
        config = {
          WorkingDir = "/opt/product-opener";
          ExposedPorts = { "80/tcp" = { }; };
        };
      in {
        backend-base = let
          inherit (pkgs)
            apacheHttpd bashInteractive busybox cacert gnumeric wget;
        in dockerTools.buildImage {
          name = "backend-base";
          inherit tag;
          contents = [ apacheHttpd bashInteractive cacert gnumeric wget ];
          runAsRoot = ''
            #!${pkgs.runtimeShell}
            ${dockerTools.shadowSetup}

            adduser -H -D www-data
            addgroup www-data www-data

            # src uses apache2ctl in po-foreground.sh
            # TODO: Patch
            ln -s /bin/apachectl /bin/apache2ctl

            mkdir -p /var/log/apache2
            mkdir -p /var/log/httpd

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
        # Although it would be necessary to copy in the contents of the built html folder
        # from the app... which leads to the suggesstion that it should become a derivation
        frontend = let inherit (pkgs) nginx;
        in dockerTools.buildImage {
          name = "frontend";
          inherit tag;
          contents = [ nginx ];
          runAsRoot = ''
            #!${pkgs.runtimeShell}
            # copy built html into /opt/product-opener/html
          '';
        };
      };

      nixosConfigurations.base-container = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: {
            boot.isContainer = true;

            networking.useDHCP = false;
            networking.firewall.allowedTCPPorts = [ 80 ];
          })
        ];
      };

      nixosConfigurations.apache-container = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ({ pkgs, ... }: {
            boot.isContainer = true;

            networking.useDHCP = false;
            networking.firewall.allowedTCPPorts = [ 80 ];

            services.httpd = {
              enable = true;
              adminAddr = "morty@example.org";
            };
          })
        ];
      };

    };
}
