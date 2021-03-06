{ lib, stdenv, fetchurl, gmp }:

stdenv.mkDerivation rec {
  name = "isl-0.14.1";

  src = fetchurl {
    url = "http://isl.gforge.inria.fr/${name}.tar.xz";
    sha256 = "0xa6xagah5rywkywn19rzvbvhfvkmylhcxr6z9z7bz29cpiwk0l8";
  };

  buildInputs = [ gmp ];

  enableParallelBuilding = true;

  meta = {
    homepage = "https://www.kotnet.org/~skimo/isl/";
    license = lib.licenses.lgpl21;
    description = "A library for manipulating sets and relations of integer points bounded by linear constraints";
    platforms = lib.platforms.all;
  };
}
