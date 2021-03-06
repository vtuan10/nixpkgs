{ lib, stdenv, fetchurl, makeWrapper, writeText
, autoconf, ncurses, graphviz, doxygen
, ocamlPackages, ltl2ba, coq, why3
, gdk-pixbuf, wrapGAppsHook
}:

let
  mkocamlpath = p: "${p}/lib/ocaml/${ocamlPackages.ocaml.version}/site-lib";
  runtimeDeps = with ocamlPackages; [
    apron.dev
    biniou
    camlzip
    easy-format
    menhirLib
    mlgmpidl
    num
    ocamlgraph
    stdlib-shims
    why3
    re
    seq
    sexplib
    sexplib0
    parsexp
    base
    yojson
    zarith
  ];
  ocamlpath = lib.concatMapStringsSep ":" mkocamlpath runtimeDeps;
in

stdenv.mkDerivation rec {
  pname = "frama-c";
  version = "23.0-rc1";
  slang   = "Vanadium";

  src = fetchurl {
    url    = "http://frama-c.com/download/frama-c-${version}-${slang}.tar.gz";
    sha256 = "1z9f9a217bav3vfc99kq57d5rza6j7hr91ndviwkgcaib6wc5hcv";
  };

  preConfigure = lib.optionalString stdenv.cc.isClang "configureFlagsArray=(\"--with-cpp=clang -E -C\")";

  nativeBuildInputs = [ autoconf wrapGAppsHook ];

  buildInputs = with ocamlPackages; [
    ncurses ocaml findlib ltl2ba ocamlgraph ocamlgraph_gtk yojson menhirLib camlzip
    lablgtk coq graphviz zarith apron why3 mlgmpidl doxygen
    gdk-pixbuf
  ];

  enableParallelBuilding = true;

  preFixup = ''
     gappsWrapperArgs+=(--prefix OCAMLPATH ':' ${ocamlpath})
  '';

  # Allow loading of external Frama-C plugins
  setupHook = writeText "setupHook.sh" ''
    addFramaCPath () {
      if test -d "''$1/lib/frama-c/plugins"; then
        export FRAMAC_PLUGIN="''${FRAMAC_PLUGIN-}''${FRAMAC_PLUGIN:+:}''$1/lib/frama-c/plugins"
        export OCAMLPATH="''${OCAMLPATH-}''${OCAMLPATH:+:}''$1/lib/frama-c/plugins"
      fi

      if test -d "''$1/lib/frama-c"; then
        export OCAMLPATH="''${OCAMLPATH-}''${OCAMLPATH:+:}''$1/lib/frama-c"
      fi

      if test -d "''$1/share/frama-c/"; then
        export FRAMAC_EXTRA_SHARE="''${FRAMAC_EXTRA_SHARE-}''${FRAMAC_EXTRA_SHARE:+:}''$1/share/frama-c"
      fi

    }

    addEnvHooks "$targetOffset" addFramaCPath
  '';


  meta = {
    description = "An extensible and collaborative platform dedicated to source-code analysis of C software";
    homepage    = "http://frama-c.com/";
    license     = lib.licenses.lgpl21;
    maintainers = with lib.maintainers; [ thoughtpolice amiddelk ];
    platforms   = lib.platforms.unix;
  };
}
