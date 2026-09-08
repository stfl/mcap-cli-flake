{
  description = "mcap CLI (foxglove/mcap) packaged for Nix";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    { nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: rec {
        mcap-cli = pkgs.callPackage ./package.nix { };
        default = mcap-cli;
      });

      overlays.default = final: _prev: {
        mcap-cli = final.callPackage ./package.nix { };
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt-tree);
    };
}
