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

      vivaldiCryonic = (pkgs.vivaldi.override {
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
      }).overrideAttrs (old: {
        pname = "vivaldi-cryonic";   # ← вот это главное
        # Можно ещё meta поправить, если хочешь
        meta = old.meta // {
          description = "vivaldi-cryonic — hardened Vivaldi (cryogenic edition) ❄️";
        };
      });
    
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