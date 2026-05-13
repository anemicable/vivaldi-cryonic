# vivaldi-cryonic/home.nix
{ pkgs, config, ... }:

let
  vaultPath = "${config.home.homeDirectory}/Data/Vaults/vivaldi-cryonic";   # ← новый путь
  mountPath = "${config.home.homeDirectory}/.config/vivaldi-cryonic";

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
      "--force-dark-mode"
    ];
  };
in
{
  home.packages = [ pkgs.gocryptfs pkgs.sops pkgs.fuse ];

  # Автоматическое монтирование
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
          echo "❄️  First run: initializing gocryptfs vault..."
          ${pkgs.gocryptfs}/bin/gocryptfs -init -passfile /run/secrets/vivaldi-cryonic-passphrase ${vaultPath}
        fi
        ${pkgs.gocryptfs}/bin/gocryptfs -passfile /run/secrets/vivaldi-cryonic-passphrase ${vaultPath} ${mountPath}
      ''}";
      ExecStop = "${pkgs.fuse}/bin/fusermount -u ${mountPath}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # Wrapper
  home.file.".local/bin/vivaldi-cryonic" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      echo "❄️  Launching Vivaldi Cryonic (ENCRYPTED PROFILE)..."
      exec ${vivaldiCryonic}/bin/vivaldi --user-data-dir=${mountPath} "$@"
    '';
  };

  home.activation.cryonicSetup = ''
    echo "❄️  Preparing Vivaldi Cryonic encrypted profile..."
    mkdir -p ${vaultPath} ${mountPath}
  '';
}