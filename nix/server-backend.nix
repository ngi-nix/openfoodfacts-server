{ config, lib, pkgs, src, ... }:
let
  perlWithModules = pkgs.perl.withPackages (pp:
    with pkgs.perlPackages; [
      mod_perl2
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
      # AnyURIEscape # Wasnt working perhaps needs to be updated?
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

      ### Test ###
      TestSimple13
      TestNumberDelta
      ### Develop ###
      PerlCritic
      TermReadLineGnu

      # Locally defined Dependencies
      XMLEncoding
      GraphicsColor
      BarcodeZBar # Fails its test... Tests are disabled for now
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
      LogAnyAdapterTAP
      ### Develop ###
      ApacheDB
    ]);

in {

  boot.isContainer = true;

  # system.activationScripts.test =
  #   "${src}/docker/backend-dev/conf/po-foreground.sh";
  #
  # This is a rough copy of the above script for dirty testing
  #
  system.activationScripts.copy.text = ''
    mkdir -p /opt/product-opener

    # These should really be bind mounts
    cp -r ${src}/. /opt/product-opener
    cp ${src}/docker/backend-dev/conf/Config.pm /opt/product-opener/lib/ProductOpener
    cp ${src}/docker/backend-dev/conf/Config2.pm /opt/product-opener/lib/ProductOpener

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

    chown -R wwwdata:wwwdata /mnt/podata
    chown -R wwwdata:wwwdata /opt/product-opener/html/images/products
  '';


  # Useful Test scripts
  # Once these 2 are working then we are getting somewhere
  # perl -I/opt/product-opener/lib /opt/product-opener/scripts/build_lang.pl
  # perl -I/opt/product-opener/lib /opt/product-opener/lib/startup_apache2.pl

  networking = {
    hostName = "server"; # How does this function inside a container?
    useDHCP = false;
    firewall.allowedTCPPorts = [ 80 ];
  };

  # Enable a web server.
  services.httpd = {
    enable = true;
    enablePerl = true;
    extraConfig = builtins.readFile "${src}/docker/backend-dev/conf/apache.conf";
    adminAddr = "test@test.com";
  };

  environment.systemPackages = with pkgs; [
    perlWithModules
    imagemagick
    graphviz
    tesseract
    gnumeric
  ];
}
