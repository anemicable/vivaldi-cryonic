# vivaldi-cryonic/flake.nix
{
  description = "vivaldi-cryonic — hardened Vivaldi (cryogenic edition) ❄️";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
    in
    {
      packages.${system} = {
        default = vivaldiCryonic;
        vivaldi-cryonic = vivaldiCryonic;
      };

      # Оставляем home-manager модуль как был
      homeModules.default = ./home.nix;
    };
}