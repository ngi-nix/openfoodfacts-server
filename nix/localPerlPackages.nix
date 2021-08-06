{ buildPerlPackage, lib, fetchurl, perlPackages, which, zbar, imagemagick
, tesseract }:

with perlPackages; rec {
  XMLEncoding = buildPerlPackage {
    pname = "XML-Encoding";
    version = "2.11";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SH/SHAY/XML-Encoding-2.11.tar.gz";
      sha256 =
        "a50e41af0a79b882d48816b95681f38a55af1e6a88828dcd96374a8bde2305a1";
    };
    propagatedBuildInputs = [ XMLParser ];
    meta = {
      description = "A perl module for parsing XML encoding maps";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  GraphicsColor = buildPerlPackage {
    pname = "Graphics-Color";
    version = "0.31";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GP/GPHAT/Graphics-Color-0.31.tar.gz";
      sha256 =
        "faa8fed5b2d80e5160af976e5db2242c0b3555542ce1042575ff6b694587a33d";
    };
    buildInputs = [ TestNumberDelta ModulePluggable ];
    propagatedBuildInputs = [
      ColorLibrary
      Moose
      MooseXAliases
      MooseXClone
      MooseXStorage
      MooseXTypes
    ];
    meta = {
      homepage = "https://github.com/gphat/graphics-color";
      description = "Device and library agnostic color spaces";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  BarcodeZBar = buildPerlPackage {
    pname = "Barcode-ZBar";
    version = "0.04";
    src = fetchurl {
      url = "mirror://cpan/authors/id/S/SP/SPADIX/Barcode-ZBar-0.04.tar.gz";
      sha256 =
        "d57e1ad471b6a29fa4134650e6eec9eb834d42cbe8bf8f0608c67d6dd0f8f431";
    };
    buildInputs = [ zbar ];
    meta = {
      homepage = "https://github.com/mchehab/zbar";
      description = "Perl interface to the ZBar Barcode Reader";
      license = with lib.licenses; [ gpl2Plus ];
    };
  };
  experimental = buildPerlPackage {
    pname = "experimental";
    version = "0.025";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEONT/experimental-0.025.tar.gz";
      sha256 =
        "d886deeadd2bea6ed2a0d9c127d9a36da817a4e4d5a6ecd04a6b12b234d0664e";
    };
    meta = {
      description = "Experimental features made easy";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  ExcelWriterXLSX = buildPerlPackage {
    pname = "Excel-Writer-XLSX";
    version = "1.09";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/J/JM/JMCNAMARA/Excel-Writer-XLSX-1.09.tar.gz";
      sha256 =
        "d679c6ac19e93c32ab77594c793e41b948c7bb3873b600e70ad637d093dca187";
    };
    propagatedBuildInputs = [ ArchiveZip ];
    meta = {
      homepage = "http://jmcnamara.github.com/excel-writer-xlsx/";
      description = "Create a new file in the Excel 2007+ XLSX format";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  MongoDB = buildPerlPackage {
    pname = "MongoDB";
    version = "2.2.2";
    src = fetchurl {
      url = "mirror://cpan/authors/id/M/MO/MONGODB/MongoDB-v2.2.2.tar.gz";
      sha256 =
        "201935f92dac94f39c35de73661e8b252439e496f228657db85ff93257c3268f";
    };
    buildInputs = [ JSONMaybeXS PathTiny TestDeep TestFatal TimeMoment ];
    propagatedBuildInputs = [
      AuthenSASLSASLprep
      AuthenSCRAM
      BSON
      IOSocketSSL
      NetSSLeay
      ClassXSAccessor
      BSONXS
      TypeTinyXS
      MozillaCA
      Moo
      NetDNS
      SafeIsa
      SubQuote
      TieIxHash
      TypeTiny
      UUIDURandom
      boolean
      namespaceclean
    ];
    meta = {
      homepage = "https://github.com/mongodb-labs/mongo-perl-driver";
      description = "Official MongoDB Driver for Perl (EOL)";
      license = lib.licenses.asl20;
    };
  };
  EncodePunycode = buildPerlPackage {
    pname = "Encode-Punycode";
    version = "1.002";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/C/CF/CFAERBER/Encode-Punycode-1.002.tar.gz";
      sha256 =
        "ca3aceecdb80b5d45aa10e1cde8fec4e90b4f8c9189c7504dd8658f071f77194";
    };
    buildInputs = [ TestNoWarnings ];
    propagatedBuildInputs = [ NetIDNEncode ];
    meta = {
      homepage = "http://search.cpan.org/dist/Encode-Punycode";
      description = "Encode plugin for Punycode (RFC 3492)";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  AlgorithmCheckDigits = buildPerlPackage {
    pname = "Algorithm-CheckDigits";
    version = "1.3.5";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/M/MA/MAMAWE/Algorithm-CheckDigits-v1.3.5.tar.gz";
      sha256 =
        "a956d0517180d6d9042f47d73aa6a2728b75fcbd546940d2dbe0a7e7cf428f73";
    };
    buildInputs = [ ProbePerl ModuleBuild ];
    meta = {
      description = "Perl extension to generate and test check digits";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  ImageOCRTesseract = buildPerlPackage {
    pname = "Image-OCR-Tesseract";
    version = "1.26";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/L/LE/LEOCHARRE/Image-OCR-Tesseract-1.26.tar.gz";
      sha256 =
        "98d904266a7062f09c9b46f77c4e94529e1fe99339e3f83fda1f92013f007cea";
    };
    nativeBuildInputs = [ which ];
    propagatedBuildInputs = [
      FileFindRule
      FileWhich
      LEOCHARRECLI
      StringShellQuote
      tesseract
      imagemagick
    ];
    meta = {
      description = "Read an image with tesseract ocr and get output";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  CLDRNumber = buildPerlModule {
    pname = "CLDR-Number";
    version = "0.19";
    src = fetchurl {
      url = "mirror://cpan/authors/id/P/PA/PATCH/CLDR-Number-0.19.tar.gz";
      sha256 =
        "c6716488e65fe779ff79a83f0f2036ad94463efe3d0f349c6b99112975bd85fc";
    };
    buildInputs = [ SoftwareLicense TestDifferences TestException TestWarn ];
    propagatedBuildInputs =
      [ ClassMethodModifiers MathRound Moo namespaceclean ];
    meta = {
      homepage = "https://github.com/patch/cldr-number-pm5";
      description = "Localized number formatters using the Unicode CLDR";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  DataDumperAutoEncode = buildPerlPackage {
    pname = "Data-Dumper-AutoEncode";
    version = "1.00";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/B/BA/BAYASHI/Data-Dumper-AutoEncode-1.00.tar.gz";
      sha256 =
        "2d9a0262ad443d321dc489ef6dfa7b3eed11a2708a75d397d371bb2585e5eca1";
    };
    buildInputs =
      [ ModuleBuildPluggable ModuleBuildPluggableCPANfile ModuleBuild ];
    propagatedBuildInputs = [ IOInteractiveTiny ];
    meta = {
      description = "Dump with recursive encoding";
      license = lib.licenses.artistic2;
    };
  };
  XMLRules = buildPerlPackage {
    pname = "XML-Rules";
    version = "1.16";
    src = fetchurl {
      url = "mirror://cpan/authors/id/J/JE/JENDA/XML-Rules-1.16.tar.gz";
      sha256 =
        "3788255c07afe4195a0de72ce050652320d817528ff2d10c611f6e392043868b";
    };
    nativeBuildInputs = [ ModuleBuild ];
    propagatedBuildInputs = [ XMLParser ];
    meta = {
      description =
        "Parse XML and specify what and how to keep/process for individual tags";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  TextFuzzy = buildPerlPackage {
    pname = "Text-Fuzzy";
    version = "0.29";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BK/BKB/Text-Fuzzy-0.29.tar.gz";
      sha256 =
        "3df5cfd2ca1a4c5ca7ff7bab3cc8d53ad2064e134cbf11004f3cf8c4b9055bff";
    };
    meta = {
      description = "Partial string matching using edit distances";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  SpreadsheetCSV = buildPerlPackage {
    pname = "Spreadsheet-CSV";
    version = "0.20";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DD/DDICK/Spreadsheet-CSV-0.20.tar.gz";
      sha256 =
        "070bb252a8fe8b938a1ce4fc90525f833d4e619b6d4673b0ae0a23408d514ab6";
    };
    nativeBuildInputs = [ CGI ];
    propagatedBuildInputs =
      [ ArchiveZip SpreadsheetParseExcel TextCSV_XS XMLParser ];
    meta = {
      description =
        "Drop-in replacement for Text::CSV_XS with spreadsheet support";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  FilechmodRecursive = buildPerlPackage {
    pname = "File-chmod-Recursive";
    version = "1.0.3";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/M/MI/MITHUN/File-chmod-Recursive-v1.0.3.tar.gz";
      sha256 =
        "9348ca5c5b88deadcc483b9399ef7c2e0fc2504f9058db65f3c3c53c41139aa7";
    };
    propagatedBuildInputs = [ Filechmod ];
    meta = {
      homepage = "https://github.com/mithun/perl-file-chmod-recursive";
      description = "Run chmod recursively against directories";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  DevelSize = buildPerlPackage {
    pname = "Devel-Size";
    version = "0.83";
    src = fetchurl {
      url = "mirror://cpan/authors/id/N/NW/NWCLARK/Devel-Size-0.83.tar.gz";
      sha256 =
        "757a67e0aa59ae103ea5ca092cbecc025644ebdc326731688ffab6f8823ef4b3";
    };
    meta = { license = with lib.licenses; [ artistic1 gpl1Plus ]; };
  };
  JSONCreate = buildPerlPackage {
    pname = "JSON-Create";
    version = "0.35";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BK/BKB/JSON-Create-0.35.tar.gz";
      sha256 =
        "5faefe0d833b8132568865308f3239d3cdaa1b8a1ecc9b5624dcf1efbe10683e";
    };
    propagatedBuildInputs = [ JSONParse UnicodeUTF8 ];
    meta = {
      description = "Create JSON";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  ActionCircuitBreaker = buildPerlPackage {
    pname = "Action-CircuitBreaker";
    version = "0.1";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/H/HA/HANGY/Action-CircuitBreaker-0.1.tar.gz";
      sha256 =
        "3f8f5d726fae537ab336e00a6819ae4a8596e4c5f243e772a536ef2eb6e606b1";
    };
    buildInputs = [ ActionRetry TryTiny ];
    propagatedBuildInputs = [ Moo ];
    meta = {
      homepage = "https://github.com/hangy/Action-CircuitBreaker";
      description =
        "Module to try to perform an action, with an option to suspend execution after a number of failures";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  ActionRetry = buildPerlPackage {
    pname = "Action-Retry";
    version = "0.24";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DA/DAMS/Action-Retry-0.24.tar.gz";
      sha256 =
        "a3759742c5bef2d1975ab73d35499d8113324919b24936130255cff07d0294f7";
    };
    propagatedBuildInputs = [ MathFibonacci ModuleRuntime Moo ];
    meta = {
      description =
        "Module to try to perform an action, with various ways of retrying and sleeping between retries";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  MathFibonacci = buildPerlPackage {
    pname = "Math-Fibonacci";
    version = "1.5";
    src = fetchurl {
      url = "mirror://cpan/authors/id/V/VI/VIPUL/Math-Fibonacci-1.5.tar.gz";
      sha256 =
        "70a8286e94558df99dc92f52d83e1e20a7b8f7852bcc3a1de7d9e338260b99ba";
    };
    meta = { };
  };

  ModuleBuildPluggableCPANfile = buildPerlModule {
    pname = "Module-Build-Pluggable-CPANfile";
    version = "0.05";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/K/KA/KAZEBURO/Module-Build-Pluggable-CPANfile-0.05.tar.gz";
      sha256 =
        "4aec6cba240cb6e78016406b6a3a875634cc2aec08ffc5f1572da1cdc40e1e7c";
    };
    buildInputs = [ CaptureTiny TestRequires TestSharedFork ];
    propagatedBuildInputs = [ ModuleBuildPluggable ModuleCPANfile ];
    meta = {
      homepage = "https://github.com/kazeburo/Module-Build-Pluggable-CPANfile";
      description = "Include cpanfile";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  IOInteractiveTiny = buildPerlPackage {
    pname = "IO-Interactive-Tiny";
    version = "0.2";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/D/DM/DMUEY/IO-Interactive-Tiny-0.2.tar.gz";
      sha256 =
        "45c0696505c7e4347845f5cd2512b7b1bc78fbce4cbed2b58008283fc95ea5f9";
    };
    meta = { description = "Is_interactive() without large deps"; };
  };

  Filechmod = buildPerlPackage {
    pname = "File-chmod";
    version = "0.42";
    src = fetchurl {
      url = "mirror://cpan/authors/id/X/XE/XENO/File-chmod-0.42.tar.gz";
      sha256 =
        "6cafafff68bc84215168b55ede0d191dcb57f9a3201b51d61edb2858a2407795";
    };
    meta = {
      homepage = "https://metacpan.org/dist/File-chmod";
      description = "Implements symbolic and ls chmod modes";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  ColorLibrary = buildPerlPackage {
    pname = "Color-Library";
    version = "0.021";
    src = fetchurl {
      url = "mirror://cpan/authors/id/R/RO/ROKR/Color-Library-0.021.tar.gz";
      sha256 =
        "58cbf7e333d3a4a40297abc43412b321da449c6816020e4fa6625ab079fc90a5";
    };
    buildInputs = [
      TestMost
      TestWarn
      TestException
      TestDeep
      TestDifferences
      ModulePluggable
    ];
    propagatedBuildInputs = [ ClassAccessor ClassDataInheritable ];
    meta = {
      description = "An easy-to-use and comprehensive named-color library";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  MooseXStorage = buildPerlPackage {
    pname = "MooseX-Storage";
    version = "0.53";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/MooseX-Storage-0.53.tar.gz";
      sha256 =
        "8704bfe505f66b340f62e85c9ff319c19e9670b26d4b012c91f4e103b1daace0";
    };
    buildInputs = [
      TestDeep
      TestDeepType
      TestFatal
      TestNeeds
      TestDeepJSON
      TestWithoutModule
      DigestHMAC
      MooseXTypes
    ];
    propagatedBuildInputs = [
      ModuleRuntime
      Moose
      MooseXRoleParameterized
      PodCoverage
      StringRewritePrefix
      namespaceautoclean
      IOStringy
      JSON
      JSONXS
      JSONMaybeXS
      CpanelJSONXS
      YAML
      YAMLOld
      YAMLTiny
      YAMLLibYAML
      YAMLSyck
    ];
    meta = {
      homepage = "https://github.com/moose/MooseX-Storage";
      description = "A serialization framework for Moose classes";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  TestDeepType = buildPerlPackage {
    pname = "Test-Deep-Type";
    version = "0.008";
    src = fetchurl {
      url = "mirror://cpan/authors/id/E/ET/ETHER/Test-Deep-Type-0.008.tar.gz";
      sha256 =
        "6e7bea1a2f1e75319a22d1c51996ebac50ca5e3663d1bc223130887e62e959f1";
    };
    buildInputs = [ TestFatal TestNeeds ];
    propagatedBuildInputs = [ TestDeep TryTiny ];
    meta = {
      homepage = "https://github.com/karenetheridge/Test-Deep-Type";
      description = "A Test::Deep plugin for validating type constraints";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  LEOCHARRECLI = buildPerlPackage {
    pname = "LEOCHARRE-CLI";
    version = "1.19";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LE/LEOCHARRE/LEOCHARRE-CLI-1.19.tar.gz";
      sha256 =
        "37835f11ee35326241b4d30368ae1bc195a50414b3662db3e13b865bd52fcde9";
    };
    propagatedBuildInputs =
      [ FileWhich Filechmod LEOCHARREDEBUG Linuxusermod YAML ];
    meta = { };
  };

  LEOCHARREDebug = buildPerlPackage {
    pname = "LEOCHARRE-Debug";
    version = "1.03";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/L/LE/LEOCHARRE/LEOCHARRE-Debug-1.03.tar.gz";
      sha256 =
        "c1665aa3abd457cc8624b8c418c6f8bdf58fb3a686f8eed515cf7e93514df192";
    };
    meta = {
      description = "Debug sub";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };
  LEOCHARREDEBUG = LEOCHARREDebug;

  Linuxusermod = buildPerlPackage {
    pname = "Linux-usermod";
    version = "0.69";
    src = fetchurl {
      url = "mirror://cpan/authors/id/V/VI/VIDUL/Linux-usermod-0.69.tar.gz";
      sha256 =
        "97ca186a3c416bf69ed62da046f1a60d88d89b8e6ed25008b2f96e787dee9d60";
    };
    meta = { };
  };

  BSON = buildPerlPackage {
    pname = "BSON";
    version = "1.12.2";
    src = fetchurl {
      url = "mirror://cpan/authors/id/M/MO/MONGODB/BSON-v1.12.2.tar.gz";
      sha256 =
        "f4612c0c354310741b99ab6d26451226823150ca27109b1b391232d5cfdda6db";
    };
    buildInputs = [ JSONMaybeXS PathTiny TestDeep TestFatal ];
    propagatedBuildInputs =
      [ CryptURandom Moo TieIxHash boolean namespaceclean ];
    meta = {
      homepage = "https://github.com/mongodb-labs/mongo-perl-bson";
      description = "BSON serialization and deserialization (EOL)";
      license = lib.licenses.asl20;
    };
  };

  UUIDURandom = buildPerlPackage {
    pname = "UUID-URandom";
    version = "0.001";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DA/DAGOLDEN/UUID-URandom-0.001.tar.gz";
      sha256 =
        "3f13631b13b9604fb489e2989490c99f103743a837239bdafae9d6baf55f8f46";
    };
    propagatedBuildInputs = [ CryptURandom ];
    meta = {
      homepage = "https://github.com/dagolden/UUID-URandom";
      description = "UUIDs based on /dev/urandom or the Windows Crypto API";
      license = lib.licenses.asl20;
    };
  };

  LogAnyAdapterTAP = buildPerlPackage {
    pname = "Log-Any-Adapter-TAP";
    version = "0.003003";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/N/NE/NERDVANA/Log-Any-Adapter-TAP-0.003003.tar.gz";
      sha256 =
        "131f0689b2b42b1b31449714c6eda8f811dd96a7c86748f1e03b239cfd0121c0";
    };
    propagatedBuildInputs = [ LogAny TryTiny ];
    meta = {
      homepage = "https://github.com/silverdirk/perl-Log-Any-Adapter-TAP";
      description = "Logger suitable for use with TAP test files";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  ApacheDB = buildPerlPackage {
    pname = "Apache-DB";
    version = "0.18";
    src = fetchurl {
      url = "mirror://cpan/authors/id/L/LZ/LZE/Apache-DB-0.18.tar.gz";
      sha256 =
        "6527f4f1598270bea07bec787b71bdf0ec2b572548be7438cf74f2b9a600bfed";
    };
    meta = { };
  };

  TestDeepJSON = buildPerlModule {
    pname = "Test-Deep-JSON";
    version = "0.05";
    src = fetchurl {
      url = "mirror://cpan/authors/id/M/MO/MOTEMEN/Test-Deep-JSON-0.05.tar.gz";
      sha256 =
        "aec8571b9e31b7301e26132c132c6800952dc089c645d76954a3ad1a6b350858";
    };
    buildInputs = [ ModuleBuildTiny ];
    propagatedBuildInputs = [ ExporterLite JSONMaybeXS TestDeep ];
    meta = {
      homepage = "https://github.com/motemen/perl5-Test-Deep-JSON";
      description = "Compare JSON with Test::Deep";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  YAMLOld = buildPerlPackage {
    pname = "YAML-Old";
    version = "1.23";
    src = fetchurl {
      url = "mirror://cpan/authors/id/I/IN/INGY/YAML-Old-1.23.tar.gz";
      sha256 =
        "fa546fcd9acc5a39bc8871902f7fc1eba50e7dc781c5cd5c0abf1aece6d17ecd";
    };
    buildInputs = [ TestYAML TestBase ];
    meta = {
      homepage = "https://github.com/ingydotnet/yaml-old-pm";
      description = "Old YAML.pm Legacy Code";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  MooseXStorageFormatJSONpm = buildPerlPackage {
    pname = "MooseX-Storage-Format-JSONpm";
    version = "0.093093";
    src = fetchurl {
      url =
        "mirror://cpan/authors/id/R/RJ/RJBS/MooseX-Storage-Format-JSONpm-0.093093.tar.gz";
      sha256 =
        "ebe0407a7eb1870270e0e2579f097dfd7df2aea3307fb71f324fb69e242cc58f";
    };
    buildInputs =
      [ Moose TestDeepJSON TestWithoutModule DigestHMAC MooseXTypes ];
    propagatedBuildInputs =
      [ JSON MooseXRoleParameterized MooseXStorage namespaceautoclean ];
    meta = {
      homepage = "https://github.com/rjbs/MooseX-Storage-Format-JSONpm";
      description = "A format role for MooseX::Storage using JSON.pm";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  TimeMoment = buildPerlPackage {
    pname = "Time-Moment";
    version = "0.44";
    src = fetchurl {
      url = "mirror://cpan/authors/id/C/CH/CHANSEN/Time-Moment-0.44.tar.gz";
      sha256 =
        "64acfa042f634fcef8dadf55e7f42ba4eaab8aaeb7d5212eb89815a31f78f6fd";
    };
    buildInputs = [ TestFatal TestNumberDelta TestRequires ];
    meta = {
      description = "Represents a date and time of day with an offset from UTC";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  BSONXS = buildPerlPackage {
    pname = "BSON-XS";
    version = "0.8.4";
    src = fetchurl {
      url = "mirror://cpan/authors/id/M/MO/MONGODB/BSON-XS-v0.8.4.tar.gz";
      sha256 =
        "28f7d338fd78b6f9c9a6080be9de3f5cb23d888b96ebf6fcbface9f2966aebf9";
    };
    buildInputs =
      [ ConfigAutoConf JSONMaybeXS PathTiny TestDeep TestFatal TieIxHash ];
    propagatedBuildInputs = [ BSON boolean JSONXS JSONPP CpanelJSONXS ];
    meta = {
      homepage = "https://github.com/mongodb-labs/mongo-perl-bson-xs";
      description = "XS implementation of MongoDB's BSON serialization (EOL)";
      license = lib.licenses.asl20;
    };
  };

  TypeTinyXS = buildPerlPackage {
    pname = "Type-Tiny-XS";
    version = "0.022";
    src = fetchurl {
      url = "mirror://cpan/authors/id/T/TO/TOBYINK/Type-Tiny-XS-0.022.tar.gz";
      sha256 =
        "bcc34a31f7dc1d30cc803889b5c8f90e4773b73b5becbdb3860f5abe7e22ff00";
    };
    meta = {
      homepage = "https://metacpan.org/release/Type-Tiny-XS";
      description =
        "Provides an XS boost for some of Type::Tiny's built-in type constraints";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };


}
