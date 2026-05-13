# vivaldi-cryonic/home.nix
{ pkgs, config, ... }:

let
  vaultPath = "${config.home.homeDirectory}/Vaults/vivaldi-cryonic";
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

  customIcon = "${config.home.homeDirectory}/Data/Flakes/vivaldi-cryonic/assets/icon.png";  # ← ИЗМЕНИ НА СВОЙ ПУТЬ К ИКОНКЕ
in
{
  home.packages = [ pkgs.gocryptfs pkgs.fuse pkgs.sops pkgs.desktop-file-utils ];

  # Полноценный uBlock Origin (unpacked)
  home.file."${config.xdg.configHome}/vivaldi-cryonic/Extensions/uBlock0.chromium" = {
    source = pkgs.fetchFromGitHub {
      owner = "gorhill";
      repo = "uBlock";
      rev = "1.71.0";
      sha256 = "sha256-fdnEofH/R42p1ruYDysACaEYy9+KR7hDDJnkEfAGLD8=";                       # Nix выдаст правильный sha256
    } + "/dist/build/uBlock0.chromium";
    recursive = true;
  };

  # Основной wrapper (исправленный)
  home.file.".local/bin/vivaldi-cryonic" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      echo "❄️  Launching Vivaldi Cryonic (personal)..."
      exec ${vivaldiCryonic}/bin/vivaldi --user-data-dir=${mountPath}/personal "$@"
    '';
  };

  # Desktop entry для меню
  xdg.desktopEntries.vivaldi-cryonic = {
    name = "Vivaldi Cryonic";
    comment = "Hardened Vivaldi — encrypted profile";
    exec = "/home/mistflow/.local/bin/vivaldi-cryonic %U";
    icon = customIcon;
    terminal = false;
    type = "Application";
    categories = [ "Network" "WebBrowser" ];
  };

  # Один gocryptfs vault
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
    mkdir -p ${vaultPath} ${mountPath}/personal
  '';
}