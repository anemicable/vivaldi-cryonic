# vivaldi-cryonic/flake.nix
{
  description = "vivaldi-cryonic — hardened Vivaldi (cryogenic edition) ❄️";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    my-secrets = {
      url = "path:/home/mistflow/nixos-config/secrets";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, my-secrets, ... }@inputs: {
    # ← Только это нужно для подключения из основной конфигурации
    homeModules.default = ./home.nix;
  };
}