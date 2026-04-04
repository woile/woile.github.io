{
  description = "A development shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    sukr.url = "github:woile/sukr";
    sukr.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    inputs@{
      flake-parts,
      ...
    }:
    # https://flake.parts/
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        { pkgs, inputs', ... }:
        let
          sukr = inputs'.sukr.packages.sukr;
        in
        {
          packages = {
            site = pkgs.stdenv.mkDerivation {
              name = "site";
              src = pkgs.nix-gitignore.gitignoreSource [ ] ./.;
              #
              nativeBuildInputs = with pkgs; [
                sukr
                just
                tailwindcss_4
              ];
              buildPhase = ''
                just build
              '';
              installPhase = ''
                mkdir -p $out
                cp -R public/* $out
              '';
            };
          };
          # Default shell opened with `nix develop`
          devShells.default = pkgs.mkShell {
            name = "dev";

            # Available packages on https://search.nixos.org/packages
            buildInputs = with pkgs; [
              just
              sukr
              miniserve
              tailwindcss_4
              tailwindcss-language-server
              gemini-cli
              watchexec
              mozjpeg
            ];

            shellHook = ''
              echo "Welcome to the woile.dev source code!"
              just --list
            '';
          };
        };
    };
}
