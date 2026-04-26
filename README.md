# falkordb-flake

Nix flake that packages the [FalkorDB](https://www.falkordb.com) Redis module. FalkorDB is a graph database loaded into Redis as a `.so` module; it exposes a Cypher-compatible query interface via the `GRAPH.*` command family.

## Supported platforms

| Nix system | Binary |
|---|---|
| `aarch64-darwin` | `falkordb-macos-arm64v8.so` |
| `x86_64-linux` | `falkordb-x64.so` |
| `aarch64-linux` | `falkordb-arm64v8.so` |

Binaries are fetched from the [FalkorDB GitHub releases](https://github.com/FalkorDB/FalkorDB/releases). On Linux, `autoPatchelfHook` rewrites the ELF RPATH so the module links against Nix store libraries. On macOS, `install_name_tool` repoints the hardcoded Homebrew OpenSSL paths to the Nix store.

## Usage

Add the flake as an input and consume the package:

```nix
{
  inputs = {
    falkordb.url = "github:your-org/falkordb-flake";
  };

  outputs = { falkordb, ... }: {
    # falkordb.packages.${system}.default  →  $out/lib/falkordb.so
  };
}
```

The module `.so` ends up at `$out/lib/falkordb.so`. Pass it to Redis with `--loadmodule`:

```sh
redis-server --loadmodule $(nix build .#falkordb --print-out-paths)/lib/falkordb.so
```

FalkorDB's license is [SSPL](https://www.mongodb.com/licensing/server-side-public-license), so you need `config.allowUnfree = true` in your nixpkgs import.

## Building locally

```sh
nix build
```

## Updating

`update.sh` fetches the latest release from GitHub, downloads each platform binary, computes SRI hashes, and patches `package.nix` in place:

```sh
nix-shell update.sh   # or just run it directly if the shebang resolves
```

A GitHub Action (`.github/workflows/update-falkordb.yaml`) runs this daily and opens a PR when a new version is available.
