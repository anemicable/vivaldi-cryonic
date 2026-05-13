# vivaldi-cryonic/home.nix
{ pkgs, config, ... }:

let
  vaultPath   = "${config.home.homeDirectory}/Vaults/vivaldi-cryonic";
  mountPath   = "${config.home.homeDirectory}/.config/vivaldi-cryonic";
  profilePath = "${mountPath}/personal";   # твоя текущая папка

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
      "--disable-reading-from-canvas"  # (если готов потерять пару сайтов)
      "--disable-3d-apis"              # опционально
      "--force-webrtc-ip-handling-policy=disable_non_proxied_udp"
      "--enable-features=StrictOriginIsolation"
      "--force-dark-mode"
    ];
  };
in
{
  home.packages = [ pkgs.gocryptfs pkgs.fuse pkgs.sops ];

  # Wrapper
  home.file.".local/bin/vivaldi-cryonic" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      echo "❄️  Launching Vivaldi Cryonic..."
      exec ${vivaldiCryonic}/bin/vivaldi --user-data-dir=${profilePath} "$@"
    '';
  };

  # Иконка в меню
  xdg.desktopEntries.vivaldi-cryonic = {
    name = "Vivaldi Cryonic";
    comment = "Hardened Vivaldi";
    exec = "/home/mistflow/.local/bin/vivaldi-cryonic %U";
    icon = "${config.home.homeDirectory}/Data/Flakes/vivaldi-cryonic/assets/icon2.png";
    terminal = false;
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
  };

  # gocryptfs
  systemd.user.services.vivaldi-cryonic-mount = {
    Unit = {
      Description = "Mount vivaldi-cryonic gocryptfs vault";
      After = [ "sops-nix.service" "graphical-session.target" ];
      Requires = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "mount-vivaldi-cryonic" ''
        set -e
        mkdir -p ${vaultPath} ${mountPath}
        if [ ! -f ${vaultPath}/gocryptfs.conf ]; then
          echo "❄️ First run: initializing gocryptfs vault..."
          ${pkgs.gocryptfs}/bin/gocryptfs -init -passfile ${config.sops.secrets."vivaldi-cryonic-passphrase".path} ${vaultPath}
        fi
        ${pkgs.gocryptfs}/bin/gocryptfs -passfile ${config.sops.secrets."vivaldi-cryonic-passphrase".path} ${vaultPath} ${mountPath}
      ''}";
      ExecStop = "${pkgs.fuse}/bin/fusermount -u ${mountPath}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.activation.cryonicSetup = ''
    echo "❄️  Preparing Vivaldi Cryonic profile..."
    mkdir -p ${profilePath}
  '';
}