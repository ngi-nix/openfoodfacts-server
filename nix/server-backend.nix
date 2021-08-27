{ config, lib, pkgs, src, ... }:
let
  inherit (lib) mkEnableOption mkIf mkOption types;

  cfg = config.services.openfoodfacts;

  perlWithModules = pkgs.perl.withPackages (pp:
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
  options.services.openfoodfacts = {
    enable = mkEnableOption "openfoodfacts server";

    product-db = mkOption {
      type = types.str;
      options = [ "none" "minimal" "full" ];
      default = "minimal";
    };

    enableDebugPerlPackages = mkOption {
      type = types.bool;
      default = false;
      description = "Add debug perl modules and pkgs to the PATH";
    };
  };

  config = mkIf cfg.enable {
    # For debugging to test whether perl is building
    # nix build .#nixosConfigurations.container.config.system.build.perl
    system.build.perl = perlWithModules;
    # Based on the dockerfile `docker/backend/Dockerfile`
    # system.activationScripts.test =
    #   "${src}/docker/backend-dev/conf/po-foreground.sh";
    #
    # This is a rough copy of the above script for dirty testing
    #
    system.activationScripts.copy.text = ''
      mkdir -p /opt/product-opener

      # These should really be bind mounts
      cp -r ${src}/. /opt/product-opener

      patchShebangs /opt/product-opener/lib/startup_apache.pl

      mkdir -p /mnt/podata/products /mnt/podata/logs /mnt/podata/users /mnt/podata/po /mnt/podata/orgs
      ln -sf /opt/product-opener/lang /mnt/podata/lang
      ln -sf /opt/product-opener/po/common /mnt/podata/po/common
      ln -sf /opt/product-opener/po/openfoodfacts /mnt/podata/po/site-specific
      ln -sf /opt/product-opener/po/tags /mnt/podata/po/tags
      ln -sf /opt/product-opener/taxonomies /mnt/podata/taxonomies
      ln -sf /opt/product-opener/ingredients /mnt/podata/ingredients
      ln -sf /opt/product-opener/emb_codes /mnt/podata/emb_codes
      ln -sf /opt/product-opener/packager-codes /mnt/podata/packager-codes
      ln -sf /opt/product-opener/ecoscore /mnt/podata/ecoscore
      ln -sf /opt/product-opener/forest-footprint /mnt/podata/forest-footprint
      ln -sf /opt/product-opener/templates /mnt/podata/templates

      ln -sf /opt/product-opener/docker/backend-dev/conf/log.conf /mnt/podata/log.conf
      ln -sf /opt/product-opener/docker/backend-dev/conf/minion_log.conf /mnt/podata/minion_log.conf

      chown -R wwwdata:wwwdata /mnt/podata
      chown -R wwwdata:wwwdata /opt/product-opener/html/images/products

      perl /opt/product-opener/scripts/build_lang.pl
    '';

    # Useful Test scripts
    # Once these 2 are working then we are getting somewhere
    # perl /opt/product-opener/scripts/build_lang.pl
    # perl /opt/product-opener/lib/startup_apache2.pl

    # To test a perl module is working and loaded:
    # perl -e "use <Module>" ie perl -e "use Barcode::Zbar"
    # Get list of all installed modules
    # perl -MFile::Find=find -MFile::Spec::Functions -Tlwe 'find { wanted => sub { print canonpath $_ if /\.pm\z/ }, no_chdir => 1 }, @INC' > /var/log/httpd/modules.txt
    # https://theunixshell.blogspot.com/2012/12/check-for-installed-modules-in-perl.html
    # To show the @INC
    # perl -e "print \"@INC\""
    #
    # The new problem is that the perl that apache httpd is using to run the perl code is different
    # from the one in the environment and therefore does have access to perl packages
    # included on the @INC file throught PerlWithModules
    # This seems like a job for patchShebangs which therefor means I need to put all this
    # into a derivation

    networking = {
      useDHCP = false;
      firewall.allowedTCPPorts = [ 80 ];
    };

    # Enable a web server.
    services.httpd = {
      enable = true;
      enablePerl = true;
      # perlPackage = perlWithModules;
      adminAddr = "test@test.com";
      extraConfig =
        (''
          PerlSwitches -I${pkgs.product-opener}
          PerlSwitches -I${perlWithModules}/lib/perl5/site_perl
          '' + (builtins.readFile "${src}/docker/backend-dev/conf/apache.conf"));
    };

    environment.variables.PERL5LIB = "${pkgs.product-opener}";
    environment.systemPackages = with pkgs; [
      perlWithModules
    ];
  };
}
