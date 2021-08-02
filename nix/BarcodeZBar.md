# Building BarcodeZBar
https://metacpan.org/release/SPADIX/Barcode-ZBar-0.04

## Thoughts 
What is failing this build is the following lines:
```
perl5.34.0-Barcode-ZBar> ZBar.xs: In function 'XS_Barcode__ZBar_version':
perl5.34.0-Barcode-ZBar> ZBar.xs:202:9: error: too few arguments to function 'zbar_version'
```

It seems this program was last updated in 2016 with the last changes to the build process in 2009 :(
https://metacpan.org/dist/Barcode-ZBar/source
https://metacpan.org/dist/Barcode-ZBar

And since then upstream has changed so that the 'XS_Barcode__ZBar_version' now requires 3 arguments (it includes a patch arg).

For reference see this python ZBar wrapper: https://github.com/rxwen/zbar/commit/155ba45b9ecad968e3d9773d0db9cbc23e900c61

So two options to fix this is might be:
1. patch the function so that it takes this third argument 
2. create an overlay for zbar for a version before it cohered to semver.

### Overlay
This wasnt very successful as it seems the compilation has changed significantly between versions... so much so that overriding all the attrs with ones from a version built in a previous git commit still failed. https://github.com/NixOS/nixpkgs/blob/57ffe86efa988788b6c58a1e3b682ee8f80c74a3/pkgs/tools/graphics/zbar/default.nix

Final attempt was to test it with these previous packages by using directly using these previous builds by way of [Nix Package Versions](https://lazamar.co.uk/nix-versions/?package=zbar&version=0.10&fullName=zbar-0.10&keyName=zbar&revision=12408341763b8f2f0f0a88001d9650313f6371d5&channel=nixpkgs-unstable#instructions)

```
zbar = final: prev: {
     zbar = (import (builtins.fetchGit {
       url = "https://github.com/NixOS/nixpkgs/";
       ref = "refs/heads/nixpkgs-unstable";
       rev = "12408341763b8f2f0f0a88001d9650313f6371d5";
       }) { system = "x86_64-linux"; }).zbar;
};
```

Tested this with all the previous versions in nixpkgs and they all failed with the same log (Too few args) apart from version 0.10 which failed to build the PerlModule for completely different reasons.

### With Patch

It is sucessfully compiling using the generated make file stage but failing all the tests as it can't load the just built module:
```
 Error:  Can't load '/home/thomassdk/Downloads/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so' for module Barcode::ZBar: /home/thomassdk/Downloads/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so: undefined symbol: zbar_scanner_reset at /nix/store/07j6d0lr6p1gjxi2qhf6wn88nl81x5jj-perl-5.32.1/lib/perl5/5.32.1/x86_64-linux-thread-multi/DynaLoader.pm line 193.
```

I cannot see what is wrong here except for perhaps:
`Warning (mostly harmless): No library found for -lzbar`

Adding `pkg-config` to the buildInputs did not help here...

#### Patch
```
From e51b51a77eab1251babc58929a4d2107172a041f Mon Sep 17 00:00:00 2001
From: Thomas Sean Dominic Kelly <thomassdk@pm.me>
Date: Fri, 6 Aug 2021 12:35:06 +0100
Subject: [PATCH] version patch

---
 ZBar.xs | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/ZBar.xs b/ZBar.xs
index ad6fc56..97bd2c0 100644
--- a/ZBar.xs
+++ b/ZBar.xs
@@ -198,9 +198,10 @@ zbar_version()
     PREINIT:
 	unsigned major;
         unsigned minor;
+        unsigned patch;
     CODE:
-        zbar_version(&major, &minor);
-        RETVAL = newSVpvf("%u.%u", major, minor);
+        zbar_version(&major, &minor, &patch);
+        RETVAL = newSVpvf("%u.%u.%u", major, minor, patch);
     OUTPUT:
         RETVAL
 
-- 
2.32.0

```
#### Code
Grepping through the codebase to find modules that it might use lead me to these buildInputs.
```
BarcodeZBar = buildPerlPackage {
  pname = "Barcode-ZBar";
  version = "0.04";
  src = fetchurl {
    url = "mirror://cpan/authors/id/S/SP/SPADIX/Barcode-ZBar-0.04.tar.gz";
    sha256 =
      "d57e1ad471b6a29fa4134650e6eec9eb834d42cbe8bf8f0608c67d6dd0f8f431";
  };
  patches = [ ./0001-version-patch.patch ];
  buildInputs = [
    pkg-config
    TestMore
  ];
  propagatedBuildInputs = [ zbar ImageMagick ];
  meta = {
    homepage = "https://github.com/mchehab/zbar";
    description = "Perl interface to the ZBar Barcode Reader";
    license = with lib.licenses; [ gpl2Plus ];
  };
};
```

#### Logs
<details>
    <summary>Click to see full logs</summary>

```
[nix-shell:~/summer-of-nix/openfoodfacts-server/nix]$ nix-build test.nix
this derivation will be built:
  /nix/store/gww59146rs399rjc3fnawrjng4pqf6dl-perl5.32.1-Barcode-ZBar-0.04.drv
building '/nix/store/gww59146rs399rjc3fnawrjng4pqf6dl-perl5.32.1-Barcode-ZBar-0.04.drv'...
unpacking sources
unpacking source archive /nix/store/g5kazmm00923w6rgcf5h6rzrlp7b1nhj-Barcode-ZBar-0.04.tar.gz
source root is Barcode-ZBar-0.04
setting SOURCE_DATE_EPOCH to timestamp 1256327204 of file Barcode-ZBar-0.04/META.yml
patching sources
applying patch /nix/store/3ix6dz6lmifqrmbs24jbjh9z07wbscbi-0001-version-patch.patch
patching file ZBar.xs
configuring
patching ./examples/processor.pl...
patching ./examples/scan_image.pl...
patching ./examples/read_one.pl...
patching ./examples/paginate.pl...
Checking if your kit is complete...
Looks good
Use of uninitialized value $thispth in concatenation (.) or string at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/ExtUtils/Liblist/Kid.pm line 162.
Use of uninitialized value $thispth in concatenation (.) or string at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/ExtUtils/Liblist/Kid.pm line 166.
Use of uninitialized value $thispth in concatenation (.) or string at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/ExtUtils/Liblist/Kid.pm line 171.
Use of uninitialized value $thispth in concatenation (.) or string at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/ExtUtils/Liblist/Kid.pm line 173.
Use of uninitialized value $thispth in concatenation (.) or string at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/ExtUtils/Liblist/Kid.pm line 181.
Use of uninitialized value $thispth in concatenation (.) or string at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/ExtUtils/Liblist/Kid.pm line 183.
Use of uninitialized value $thispth in concatenation (.) or string at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/ExtUtils/Liblist/Kid.pm line 187.
Warning (mostly harmless): No library found for -lzbar
Generating a Unix-style Makefile
Writing Makefile for Barcode::ZBar
Invalid LICENSE value 'lgpl' ignored
Writing MYMETA.yml and MYMETA.json
no configure script, doing nothing
building
build flags: SHELL=/nix/store/xvvgw9sb8wk6d2c0j3ybn7sll67s3s4z-bash-4.4-p23/bin/bash
cp ZBar.pm blib/lib/Barcode/ZBar.pm
cp ZBar/Processor.pod blib/lib/Barcode/ZBar/Processor.pod
cp ZBar/ImageScanner.pod blib/lib/Barcode/ZBar/ImageScanner.pod
cp ZBar/Image.pod blib/lib/Barcode/ZBar/Image.pod
cp ZBar/Symbol.pod blib/lib/Barcode/ZBar/Symbol.pod
Running Mkbootstrap for ZBar ()
chmod 644 "ZBar.bs"
"/nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/bin/perl" -MExtUtils::Command::MM -e 'cp_nonempty' -- ZBar.bs blib/arch/auto/Barcode/ZBar/ZBar.bs 644
"/nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/bin/perl" "/nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/ExtUtils/xsubpp"  -typemap '/nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/ExtUtils/typemap' -typemap '/build/Barcode-ZBar-0.04/typemap'  ZBar.xs > ZBar.xsc
mv ZBar.xsc ZBar.c
cc -c   -D_REENTRANT -D_GNU_SOURCE -fwrapv -fno-strict-aliasing -pipe -fstack-protector-strong -I/no-such-path/include -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -O2   -DVERSION=\"0.04\" -DXS_VERSION=\"0.04\" -fPIC "-I/nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/x86_64-linux-thread-multi/CORE"   ZBar.c
rm -f blib/arch/auto/Barcode/ZBar/ZBar.so
cc  -shared -O2 -L/nix/store/gk42f59363p82rg2wv2mfy71jn5w4q4c-glibc-2.32-48/lib -fstack-protector-strong  ZBar.o  -o blib/arch/auto/Barcode/ZBar/ZBar.so  \
      \

chmod 755 blib/arch/auto/Barcode/ZBar/ZBar.so
Manifying 5 pod documents
running tests
check flags: SHELL=/nix/store/xvvgw9sb8wk6d2c0j3ybn7sll67s3s4z-bash-4.4-p23/bin/bash VERBOSE=y test
"/nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/bin/perl" -MExtUtils::Command::MM -e 'cp_nonempty' -- ZBar.bs blib/arch/auto/Barcode/ZBar/ZBar.bs 644
PERL_DL_NONLAZY=1 "/nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/bin/perl" "-MExtUtils::Command::MM" "-MTest::Harness" "-e" "undef *Test::Harness::Switches; test_harness(0, 'blib/lib', 'blib/arch')" t/*.t
t/Decoder.t ....... 1/13
#   Failed test 'use Barcode::ZBar;'
#   at t/Decoder.t line 10.
#     Tried to use 'Barcode::ZBar'.
#     Error:  Can't load '/build/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so' for module Barcode::ZBar: /build/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so: undefined symbol: zbar_scanner_reset at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/x86_64-linux-thread-multi/DynaLoader.pm line 193.
#  at t/Decoder.t line 10.
# Compilation failed in require at t/Decoder.t line 10.
# BEGIN failed--compilation aborted at t/Decoder.t line 10.
Bareword "Barcode::ZBar::Symbol::PARTIAL" not allowed while "strict subs" in use at t/Decoder.t line 48.
Bareword "Barcode::ZBar::Symbol::NONE" not allowed while "strict subs" in use at t/Decoder.t line 27.
Bareword "Barcode::ZBar::SPACE" not allowed while "strict subs" in use at t/Decoder.t line 57.
Bareword "Barcode::ZBar::Symbol::QRCODE" not allowed while "strict subs" in use at t/Decoder.t line 61.
Bareword "Barcode::ZBar::Config::ENABLE" not allowed while "strict subs" in use at t/Decoder.t line 61.
Bareword "Barcode::ZBar::Symbol::PARTIAL" not allowed while "strict subs" in use at t/Decoder.t line 69.
Bareword "Barcode::ZBar::Symbol::NONE" not allowed while "strict subs" in use at t/Decoder.t line 69.
Bareword "Barcode::ZBar::Symbol::EAN13" not allowed while "strict subs" in use at t/Decoder.t line 73.
Bareword "Barcode::ZBar::BAR" not allowed while "strict subs" in use at t/Decoder.t line 81.
Bareword "Barcode::ZBar::Symbol::EAN13" not allowed while "strict subs" in use at t/Decoder.t line 85.
Execution of t/Decoder.t aborted due to compilation errors.
# Looks like your test exited with 255 just after 1.
t/Decoder.t ....... Dubious, test returned 255 (wstat 65280, 0xff00)
Failed 13/13 subtests
t/Image.t ......... 1/22
#   Failed test 'use Barcode::ZBar;'
#   at t/Image.t line 10.
#     Tried to use 'Barcode::ZBar'.
#     Error:  Can't load '/build/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so' for module Barcode::ZBar: /build/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so: undefined symbol: zbar_scanner_reset at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/x86_64-linux-thread-multi/DynaLoader.pm line 193.
#  at t/Image.t line 10.
# Compilation failed in require at t/Image.t line 10.
# BEGIN failed--compilation aborted at t/Image.t line 10.
Bareword "Barcode::ZBar::Symbol::EAN13" not allowed while "strict subs" in use at t/Image.t line 101.
Execution of t/Image.t aborted due to compilation errors.
# Looks like your test exited with 255 just after 1.
t/Image.t ......... Dubious, test returned 255 (wstat 65280, 0xff00)
Failed 22/22 subtests
t/pod-coverage.t .. skipped: Test::Pod::Coverage required for testing pod coverage
t/pod.t ........... skipped: Test::Pod 1.00 required for testing POD
t/Processor.t ..... 1/20
#   Failed test 'use Barcode::ZBar;'
#   at t/Processor.t line 10.
#     Tried to use 'Barcode::ZBar'.
#     Error:  Can't load '/build/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so' for module Barcode::ZBar: /build/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so: undefined symbol: zbar_scanner_reset at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/x86_64-linux-thread-multi/DynaLoader.pm line 193.
#  at t/Processor.t line 10.
# Compilation failed in require at t/Processor.t line 10.
# BEGIN failed--compilation aborted at t/Processor.t line 10.
Bareword "Barcode::ZBar::Symbol::EAN13" not allowed while "strict subs" in use at t/Processor.t line 58.
Execution of t/Processor.t aborted due to compilation errors.
# Looks like your test exited with 255 just after 1.
t/Processor.t ..... Dubious, test returned 255 (wstat 65280, 0xff00)
Failed 20/20 subtests
t/Scanner.t ....... 1/3
#   Failed test 'use Barcode::ZBar;'
#   at t/Scanner.t line 10.
#     Tried to use 'Barcode::ZBar'.
#     Error:  Can't load '/build/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so' for module Barcode::ZBar: /build/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so: undefined symbol: zbar_scanner_reset at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/x86_64-linux-thread-multi/DynaLoader.pm line 193.
#  at t/Scanner.t line 10.
# Compilation failed in require at t/Scanner.t line 10.
# BEGIN failed--compilation aborted at t/Scanner.t line 10.
Can't locate object method "new" via package "Barcode::ZBar::Scanner" (perhaps you forgot to load "Barcode::ZBar::Scanner"?) at t/Scanner.t line 14.
# Looks like your test exited with 255 just after 1.
t/Scanner.t ....... Dubious, test returned 255 (wstat 65280, 0xff00)
Failed 3/3 subtests
t/ZBar.t .......... 1/3
#   Failed test 'use Barcode::ZBar;'
#   at t/ZBar.t line 10.
#     Tried to use 'Barcode::ZBar'.
#     Error:  Can't load '/build/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so' for module Barcode::ZBar: /build/Barcode-ZBar-0.04/blib/arch/auto/Barcode/ZBar/ZBar.so: undefined symbol: zbar_scanner_reset at /nix/store/n7hbdyp3bsmdxy2lcxivaxnq4nv8ndv3-perl-5.32.1/lib/perl5/5.32.1/x86_64-linux-thread-multi/DynaLoader.pm line 193.
#  at t/ZBar.t line 10.
# Compilation failed in require at t/ZBar.t line 10.
# BEGIN failed--compilation aborted at t/ZBar.t line 10.
Undefined subroutine &Barcode::ZBar::version called at t/ZBar.t line 14.
# Looks like your test exited with 255 just after 1.
t/ZBar.t .......... Dubious, test returned 255 (wstat 65280, 0xff00)
Failed 3/3 subtests

Test Summary Report
-------------------
t/Decoder.t     (Wstat: 65280 Tests: 1 Failed: 1)
  Failed test:  1
  Non-zero exit status: 255
  Parse errors: Bad plan.  You planned 13 tests but ran 1.
t/Image.t       (Wstat: 65280 Tests: 1 Failed: 1)
  Failed test:  1
  Non-zero exit status: 255
  Parse errors: Bad plan.  You planned 22 tests but ran 1.
t/Processor.t   (Wstat: 65280 Tests: 1 Failed: 1)
  Failed test:  1
  Non-zero exit status: 255
  Parse errors: Bad plan.  You planned 20 tests but ran 1.
t/Scanner.t     (Wstat: 65280 Tests: 1 Failed: 1)
  Failed test:  1
  Non-zero exit status: 255
  Parse errors: Bad plan.  You planned 3 tests but ran 1.
t/ZBar.t        (Wstat: 65280 Tests: 1 Failed: 1)
  Failed test:  1
  Non-zero exit status: 255
  Parse errors: Bad plan.  You planned 3 tests but ran 1.
Files=7, Tests=5,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.20 cusr  0.03 csys =  0.25 CPU)
Result: FAIL
Failed 5/7 test programs. 5/5 subtests failed.
make: *** [Makefile:1040: test_dynamic] Error 255
error: builder for '/nix/store/gww59146rs399rjc3fnawrjng4pqf6dl-perl5.32.1-Barcode-ZBar-0.04.drv' failed with exit code 2;
       last 10 log lines:
       >   Non-zero exit status: 255
       >   Parse errors: Bad plan.  You planned 3 tests but ran 1.
       > t/ZBar.t        (Wstat: 65280 Tests: 1 Failed: 1)
       >   Failed test:  1
       >   Non-zero exit status: 255
       >   Parse errors: Bad plan.  You planned 3 tests but ran 1.
       > Files=7, Tests=5,  0 wallclock secs ( 0.02 usr  0.00 sys +  0.20 cusr  0.03 csys =  0.25 CPU)
       > Result: FAIL
       > Failed 5/7 test programs. 5/5 subtests failed.
       > make: *** [Makefile:1040: test_dynamic] Error 255
       For full logs, run 'nix log /nix/store/gww59146rs399rjc3fnawrjng4pqf6dl-perl5.32.1-Barcode-ZBar-0.04.drv'.
```
</details>

