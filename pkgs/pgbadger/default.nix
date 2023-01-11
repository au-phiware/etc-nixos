with (import <nixpkgs> {});
buildPerlPackage rec {
  pname = "pgbadger";
  version = "11.5";
  src = fetchurl {
    url = "https://github.com/darold/${pname}/archive/refs/tags/v${version}.tar.gz";
    sha256 = "11hizysmv50bcy2902g69c3gvbdrrjcvh4pfgyykwdb11a0iias9";
  };
  buildInputs = [ pkgs.which perlPackages.PodMarkdown shortenPerlShebang perlPackages.JSONXS ];
  propagatedBuildInputs = [ pkgs.perl ];
  outputs = [ "out" ]; # no "dev" "devdoc"
  configurePhase = ''
    perl Makefile.PL INSTALLDIRS=vendor DESTDIR=$out/bin
  '';
  preBuild = ''
    shortenPerlShebang pgbadger
    patchShebangs pgbadger
  '';
}
