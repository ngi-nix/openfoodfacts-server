{ config, lib, pkgs, src, ... }:
let
  perlWithModules = pkgs.perl.withPackages (pp:
    with pkgs.perlPackages; [
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
      XMLFeedPP
      libapreq2
      DigestMD5File
      TimeLocal
      TemplateToolkit
      AnyURIEscape
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

      ### Test ###
      LogAnyAdapterTAP
      ### Develop ###
      ApacheDB
    ]);
in {

  boot.isContainer = true;

  networking = {
    # hostName = "server"; # How does this function inside a container?
    useDHCP = false;
    firewall.allowedTCPPorts = [ 80 ];
  };

  # Enable a web server.
  services.httpd = {
    enable = true;
    enablePerl = true;
    # configFile =
    #   "${inputs.openfoodfacts-server-src}/docker/backend-dev/conf/apache.conf";
    adminAddr = "morty@example.org";

    virtualHosts.localhost = {
      documentRoot = src;
    };
  };

  environment.systemPackages = with pkgs; [
    perlWithModules
    apacheHttpd
    imagemagick
    graphviz
    tesseract
    gnumeric
  ];
}
