{ pkgs ? import <nixpkgs> {}, ...}:
let pkgs22_05 = (builtins.fetchTarball { 
    url = "https://nixos.org/channels/nixos-22.05/nixexprs.tar.xz"; 
  }) {};
  php52 = import ./php52.nix pkgs22_05;
  lib = import ./lib.nix pkgs;
in php52 // lib
