{
  description = "GitHub Automations for the nixpkgs I maintain";

  inputs = {
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [ inputs.treefmt-nix.flakeModule ];
      systems = [
        "aarch64-linux"
        "x86_64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        { config, pkgs, ... }:
        {
          devShells = {
            default = pkgs.mkShell {

              name = "nixpkgs-update-gha";
              inputsFrom = [
                config.treefmt.build.devShell
              ];
              packages = with pkgs; [
                nixd
              ];
            };
          };
          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              actionlint.enable = true;
              deadnix.enable = true;
              keep-sorted.enable = true;
              mdformat = {
                enable = true;
                plugins = ps: [
                  ps.mdformat-frontmatter
                ];
              };
              nixfmt.enable = true;
              statix.enable = true;
              yamlfmt.enable = true;
            };
          };
        };
    };
}
