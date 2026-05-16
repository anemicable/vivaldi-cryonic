# vivaldi-cryonic/flake.nix
{
  description = "vivaldi-cryonic + vivaldi-stable";

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

      # ==================== Cryonic (приватный / hardened) ====================
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
          "--disable-3d-apis"
          "--force-webrtc-ip-handling-policy=disable_non_proxied_udp"
          #"--disable-reading-from-canvas"
          #"--fingerprinting-canvas-image-data-noise"
          #"--fingerprinting-canvas-measuretext-noise"
          #"--fingerprinting-client-rects-noise"
          "--enable-features=StrictOriginIsolation"
          "--disable-features=OptimizationHints,InterestFeedContentSuggestions"
          "--force-dark-mode"
        ];
      }).overrideAttrs (old: {
        pname = "vivaldi-cryonic";
        meta = old.meta // {
          description = "vivaldi-cryonic — hardened Vivaldi (cryogenic edition) ❄️";
        };
      });

      # ==================== Stable (комфортный / "гражданинский") ====================
      vivaldiStable = (pkgs.vivaldi.override {
        proprietaryCodecs = true;
        enableWidevine = true;
        commandLineArgs = [
          "--no-first-run"
          "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,VaapiVideoDecoder"
          "--ignore-gpu-blocklist"
          "--enable-gpu-rasterization"
          "--enable-accelerated-2d-canvas"
          "--force-dark-mode"
          "--password-store=basic"
        ];
      }).overrideAttrs (old: {
        pname = "vivaldi-stable";
        meta = old.meta // {
          description = "vivaldi-stable — comfortable everyday version";
        };
      });

    in
    {
      packages.${system} = {
        default = vivaldiCryonic;
        vivaldi-cryonic = vivaldiCryonic;
        vivaldi-stable = vivaldiStable;
      };

      homeModules.default = ./home.nix;
    };
}