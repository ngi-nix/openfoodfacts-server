{ pkgs, pkgsAncient }:

let zbar = pkgsAncient.zbar; in

with pkgs;
with perlPackages;

buildPerlPackage {
  pname = "Barcode-ZBar";
  version = "0.04";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SP/SPADIX/Barcode-ZBar-0.04.tar.gz";
    sha256 = "d57e1ad471b6a29fa4134650e6eec9eb834d42cbe8bf8f0608c67d6dd0f8f431";
  };
  doCheck = false;
  buildInputs = [ pkg-config TestMore ExtUtilsMakeMaker TestHarness ];
  propagatedBuildInputs = [ zbar PerlMagick ];
  meta = {
    homepage = "https://github.com/mchehab/zbar";
    description = "Perl interface to the ZBar Barcode Reader";
    license = with lib.licenses; [ gpl2Plus ];
  };
}

# TestHarness
/*
buildPerlPackage {
  pname = "Test-Harness";
  version = "3.42";
  src = fetchurl {
    url = "mirror://cpan/authors/id/L/LE/LEONT/Test-Harness-3.42.tar.gz";
    sha256 = "0fd90d4efea82d6e262e6933759e85d27cbcfa4091b14bf4042ae20bab528e53";
  };
  # shebang    => '#!/usr/bin/perl',
  # needs to become
  # $got->{shebang} = '#!/usr/bin/perl -I/nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/site_perl -I/nix/store/s2gcnrb4xrr0410y1ny9f6vhv79rwb43-perl5.32.1-Test-Harness-3.42/lib/perl5/site_perl'
  postConfigure = ''
    source $stdenv/setup
    echo "patching source.t"
    FILE_TO_PATCH=$(find . -type f -name "source.t")
    sed -i 's|\/perl\'|#\!test|' $FILE_TO_PATCH
    cat $FILE_TO_PATCH
  '';
  meta = {
    homepage = "http://testanything.org/";
    license = with lib.licenses; [ artistic1 gpl1Plus ];
  };
}
*/
