{
  inputs = {
    # build currently fails in 22.11 due to flex inserting some unexpected definition :/
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:
  let packages =  flake-utils.lib.eachDefaultSystem (system:
    {
      packages.default = import ./php52.nix { pkgs = import nixpkgs { inherit system; }; };
    });
  in {
      inherit (packages) packages;
      lib = import ./lib.nix;
      nixosModules.default = import ./module.nix packages.packages;
    };
}