{ lib, stdenv, fetchurl, autoPatchelfHook, openssl }:

let
  version = "4.18.3";

  sources = {
    "aarch64-darwin" = {
      url = "https://github.com/FalkorDB/FalkorDB/releases/download/v${version}/falkordb-macos-arm64v8.so";
      hash = "sha256-U6qY5m3FLPTZVijRFEq08yM8rflR+vgedtWnxESDVBo=";
    };
    "x86_64-linux" = {
      url = "https://github.com/FalkorDB/FalkorDB/releases/download/v${version}/falkordb-x64.so";
      hash = "sha256-R4heLaeIw/uCK5vUwYKpaU1nKGp/2P4Ywz48Gg0FY2s=";
    };
    "aarch64-linux" = {
      url = "https://github.com/FalkorDB/FalkorDB/releases/download/v${version}/falkordb-arm64v8.so";
      hash = "sha256-Eacd7TDnpJLiwwWS/drr4RmJAiTeCdmpMdhqT1ZKNNY=";
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
  buildInputs =
    lib.optionals stdenv.isLinux [ stdenv.cc.cc.lib ]
    ++ lib.optionals stdenv.isDarwin [ openssl ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib
    cp $src $out/lib/falkordb.so
    chmod 755 $out/lib/falkordb.so
    runHook postInstall
  '';

  # The macOS binary has Homebrew openssl paths hardcoded; repoint them to the
  # Nix store so the .so can be dlopen'd without Homebrew present.
  postFixup = lib.optionalString stdenv.isDarwin ''
    install_name_tool \
      -change /opt/homebrew/opt/openssl@3/lib/libssl.3.dylib \
              ${lib.getLib openssl}/lib/libssl.3.dylib \
      -change /opt/homebrew/opt/openssl@3/lib/libcrypto.3.dylib \
              ${lib.getLib openssl}/lib/libcrypto.3.dylib \
      $out/lib/falkordb.so
  '';

  passthru.updateScript = ./update.sh;

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
