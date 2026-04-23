{
  description = "FalkorDB graph database packaged for Nix";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      # Only expose the package for platforms where a binary is available.
      systems = builtins.filter
        (s: builtins.elem s [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ])
        (import inputs.systems);

      perSystem = { system, ... }:
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };
        in
        {
          packages.default = pkgs.callPackage ./package.nix { };
          packages.falkordb = pkgs.callPackage ./package.nix { };
        };
    };
}
