{ src, version, lib, fetchurl, stdenv, perl, perlPackages, apacheHttpd
, apacheHttpdPackages, imagemagick, graphviz, tesseract, gnumeric }:

stdenv.mkDerivation rec {
  name = "openfoodfacts-server-src-${version}";

  inherit src;

  apacheInputs = with apacheHttpdPackages;
    [
      # mod_perl #broken in unstable
    ];

  perlInputs = with perlPackages; [
    CGI
    TieIxHash
    LWPUserAgent
    ImageMagick # Called PerlMagick in 21.05, not building in 20.09
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

    # Locally defined Dependencies
    XMLEncoding
    GraphicsColor
    # BarcodeZBar # Doesnt build
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
  ];

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

  buildInputs = [ perl apacheHttpd imagemagick graphviz tesseract gnumeric ]
    ++ apacheInputs ++ perlInputs;

  buildPhase = "echo hello";

  meta = {
    homepage = "https://world.openfoodfacts.org/";
    description = "The backed of the Open Food Facts Server";
  };
}
