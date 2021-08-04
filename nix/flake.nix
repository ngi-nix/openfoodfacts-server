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

      server-backend = { lib, stdenv, perl, perlPackages, apacheHttpd
        , apacheHttpdPackages, imagemagick, graphviz, tesseract, gnumeric
        , extraPerlDeps }:

        stdenv.mkDerivation rec {
          name = "openfoodfacts-server-src-${version}";

          src = openfoodfacts-server-src;
          apacheDeps = with apacheHttpdPackages;
            [
              # mod_perl #broken in unstable
            ];
          perlDeps = with perlPackages; [
              CGI
              TieIxHash
              LWPUserAgent
              ImageMagick # Called PerlMagick in 21.05, not building in 21.05
              MIMELite
              CacheMemcachedFast
              JSON
              JSONPP
              Clone
              CryptPasswdMD5
              EncodeDetect
              XMLFeedPP
              # libapreq2 # has a dependency on mod_perl so also breaks the build
              DigestMD5 # see comments
              TimeLocal
              TemplateToolkit
              AnyURIEscape # Load URI::Escape::XS preferentially over URI::Escape - https://github.com/NixOS/nixpkgs/blob/2ef304b0ab9a16ab06c349ffbe16a2fb12ed340a/pkgs/top-level/perl-packages.nix#L471
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
              # On Test
              TestSimple13
              TestNumberDelta
              # On Develop
              PerlCritic
              TermReadLineGnu
            ]; # ++ lib.attrNames extraPerlDeps;

          ex = with extraPerlDeps; lib.attrNames extraPerlDeps;
          # Questions for packages
          # Is LWP::Authen::Digest part of LWP?
          # Is LWP::Simple also part of this module?
          # For example LWPUserAgent is defined at the bottom of pkgs/top-level/perl-packages.nix as
          # `LWPUserAgent = self.LWP;` but in the cpan description is is LWP::UserAgent = https://metacpan.org/pod/LWP#OVERVIEW-OF-CLASSES-AND-PACKAGES
          # https://github.com/NixOS/nixpkgs/blob/87dcf15706a844736e2ddb3d9cbb789bc4f24004/pkgs/top-level/perl-packages.nix#L24159
          # What is the self.LWP doing here?
          #
          # When generating some code dont always get the submodules eg.
          # Graphics::Color::RGB only produces a packages for GraphicsColor
          # Does this mean all the submodules are included in there?
          # Like for example the immediately following Graphic::Color:HSL
          #
          # Does this mean it is no longer need to include? Need Clarification: DigestMD5 = null; # part of Perl 5.26
          #
          # Another Submodule question
          # CLDR::Number::Format::Decimal and CLDR::Number::Format::Percent
          # Both produce only the CLDRNumber Nix attribute are they all contained here?
          #
          # Test::More = Test::Simple in nixpkgs but Test::Simple = null;
          # There is a Test::Simple13 which just seems to be TestSimple with version number
          # Why does TestSimple point to null instead of to TestSimple13?

          buildInputs =
            [ perl apacheHttpd imagemagick graphviz tesseract gnumeric ]
            ++ apacheDeps ++ perlDeps;

          buildPhase = "";

          meta = {
            homepage = "https://world.openfoodfacts.org/";
            description = "The backed of the Open Food Facts Server";
          };
        };

    in {

      # Nixpkgs overlays.
      overlays.openfoodfacts-server-backend = final: prev: {
        openfoodfacts-server-backend = final.callPackage server-backend { };
      };
      overlays.extraPerlDeps = final: prev: {
        extraPerlDeps = final.callPackage ./perlDependencies.nix { };
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
