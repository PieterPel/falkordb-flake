{ lib, stdenv, fetchurl, autoPatchelfHook }:

let
  version = "4.18.1";

  sources = {
    "aarch64-darwin" = {
      url = "https://github.com/FalkorDB/FalkorDB/releases/download/v${version}/falkordb-macos-arm64v8.so";
      hash = "sha256-7u4zI54Y/6is+hyEbH+g7kzKMX5TZoBSJug0/5fVffg=";
    };
    "x86_64-linux" = {
      url = "https://github.com/FalkorDB/FalkorDB/releases/download/v${version}/falkordb-x64.so";
      hash = "sha256-r7uPohrKRSg4lc/ag9gd6V9K4aMoNGwU41WTaPtkYfE=";
    };
    "aarch64-linux" = {
      url = "https://github.com/FalkorDB/FalkorDB/releases/download/v${version}/falkordb-arm64v8.so";
      hash = "sha256-GnDwMqosyG80FgD79JvrP9l3K5jGhqEnYHSzUdSXlk4=";
    };
  };

  platformSrc = sources.${stdenv.hostPlatform.system} or (throw ''
    falkordb: unsupported platform ${stdenv.hostPlatform.system}
    Supported platforms: ${lib.concatStringsSep ", " (lib.attrNames sources)}
  '');

in
stdenv.mkDerivation {
  pname = "falkordb";
  inherit version;

  src = fetchurl platformSrc;

  dontUnpack = true;

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook ];

  # autoPatchelfHook scans for needed libs; add more here if FalkorDB
  # pulls in extra shared libraries on Linux.
  buildInputs = lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp $src $out/lib/falkordb.so
    chmod 755 $out/lib/falkordb.so
    runHook postInstall
  '';

  meta = {
    description = "FalkorDB graph database Redis module";
    longDescription = ''
      FalkorDB is a graph database built on top of Redis. It is loaded as a
      Redis module and exposes a Cypher-compatible graph query interface via
      the GRAPH.* command family.
    '';
    homepage = "https://www.falkordb.com";
    license = lib.licenses.sspl;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.attrNames sources;
    maintainers = [ ];
  };
}
