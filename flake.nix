# vivaldi-cryonic/flake.nix
{
  description = "vivaldi-cryonic — hardened Vivaldi (cryogenic edition) ❄️";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      vivaldiCryonic = pkgs.vivaldi.override {
        proprietaryCodecs = true;
        enableWidevine = false;
        commandLineArgs = [
          "--no-first-run"
          "--disable-background-networking"
          "--disable-breakpad"
          "--disable-crash-reporter"
          "--disable-component-update"
          "--disable-sync"
          "--disable-domain-reliability"
          "--no-pings"
          "--disable-features=OptimizationGuideModelDownloading,OptimizationHintsFetching,OptimizationHints,MediaEngagementBypassAutoplayPolicies,CrashReporting,GcmRegistration,GoogleCloudMessaging"
          "--variations-server-url=0.0.0.0"
          "--connectivity-check-url=0.0.0.0"
          "--password-store=basic"
          "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiVideoDecoder"
          "--webrtc-ip-handling=disable_non_proxied_udp"
          "--disable-features=WebRTC,InterestCohort,UserAgentClientHint,AutofillServerCommunication,OptimizationHints"
          "--no-service-autorun"
          "--disable-reading-from-canvas"
          "--disable-3d-apis"
          "--force-webrtc-ip-handling-policy=disable_non_proxied_udp"
          "--enable-features=StrictOriginIsolation"
          "--force-dark-mode"
        ];
      };
    in
    {
      # Пакет теперь доступен из любой конфигурации
      packages.${system}.default = vivaldiCryonic;
      packages.${system}.vivaldi-cryonic = vivaldiCryonic;

      # Оставляем home-manager модуль как был
      homeModules.default = ./home.nix;
    };
}