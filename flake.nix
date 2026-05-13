# flake.nix
{
  description = "vivaldi-cryonic — hardened Vivaldi (cryogenic edition) ❄️";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";          # ← добавили
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    my-secrets = {
      url = "path:/home/mistflow/nixos-config/secrets";  # ← полный путь к папке secrets
      flake = false;
    };
  };

  outputs = { self, nixpkgs, home-manager, sops-nix, my-secrets, ... }@inputs:
  let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};

    # Криогенная заточенная версия Vivaldi
    vivaldiCryonic = pkgs.vivaldi.override {
      proprietaryCodecs = true;   # H.264 / VP9 и т.д. (можно false, если не нужны)
      enableWidevine = false;     # DRM — отключаем для приватности

      commandLineArgs = [
        "--no-first-run"
        "--disable-background-networking"
        "--disable-breakpad"
        "--disable-crash-reporter"
        "--disable-component-update"
        "--disable-sync"
        "--disable-domain-reliability"
        "--no-pings"
        "--disable-features=OptimizationGuideModelDownloading,OptimizationHintsFetching,OptimizationHints,MediaEngagementBypassAutoplayPolicies,CrashReporting"
        "--variations-server-url=0.0.0.0"
        "--connectivity-check-url=0.0.0.0"
        "--password-store=kwallet6"          # или gnome-libsecret / basic
        "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiVideoDecoder"
        "--force-dark-mode"
      ];
    };
  in {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {  # ← замени на свой hostname
      inherit system;
      modules = [
        ./configuration.nix
        sops-nix.nixosModules.sops
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.yourusername = import ./home.nix;  # ← свой username
        }
      ];
    };
  };
}