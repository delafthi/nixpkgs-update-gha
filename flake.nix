{
  description = "GitHub Automations for the nixpkgs I maintain";

  inputs = {
    # keep-sorted start
    flake-compat.url = "https://flakehub.com/f/edolstra/flake-compat/1.tar.gz";
    nixpkgs-update.url = "github:nix-community/nixpkgs-update";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    # keep-sorted end
  };

  nixConfig = {
    extra-substituters = "https://nix-community.cachix.org";
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
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
        { system, ... }:
        {
          packages.nixpkgs-update = inputs.nixpkgs-update.packages.${system}.default;

          treefmt = {
            projectRootFile = "flake.nix";
            programs = {
              keep-sorted.enable = true;
              nixfmt.enable = true;
              prettier.enable = true;
            };
          };
        };
    };
}
