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

  # Твоя кастомная иконка (замени путь, если нужно)
  customIcon = "${config.home.homeDirectory}/Data/Flakes/vivaldi-cryonic/assets/icon.png";   # ← ИЗМЕНИ НА СВОЙ ПУТЬ

  makeProfile = name: {
    wrapper = ''
      #!/usr/bin/env bash
      echo "❄️  Launching Vivaldi ${name} (ENCRYPTED)..."
      exec ${vivaldiCryonic}/bin/vivaldi --user-data-dir=${mountPath}/${name} "$@"
    '';

    desktop = ''
      [Desktop Entry]
      Name=Vivaldi ${name}
      Comment=Hardened Vivaldi — ${name} profile
      Exec=/home/mistflow/.local/bin/vivaldi-${name} %U
      Icon=${customIcon}
      Terminal=false
      Type=Application
      Categories=Network;WebBrowser;
      StartupWMClass=vivaldi
    '';
  };
in
{
  home.packages = [ pkgs.gocryptfs pkgs.fuse pkgs.sops ];

  # === Полноценный uBlock Origin (unpacked) ===
  home.file."${config.xdg.configHome}/vivaldi-cryonic/Extensions/uBlock0.chromium" = {
    source = pkgs.fetchFromGitHub {
      owner = "gorhill";
      repo = "uBlock";
      rev = "1.71.0";
      sha256 = "";                       # Nix выдаст правильный sha256 при первой сборке
    } + "/dist/build/uBlock0.chromium";
    recursive = true;
  };

  # === Три профиля ===
  home.file.".local/bin/vivaldi-work" = {
    executable = true;
    text = (makeProfile "Work").wrapper;
  };
  home.file.".local/share/applications/vivaldi-work.desktop" = {
    text = (makeProfile "Work").desktop;
  };

  home.file.".local/bin/vivaldi-shopping" = {
    executable = true;
    text = (makeProfile "Shopping").wrapper;
  };
  home.file.".local/share/applications/vivaldi-shopping.desktop" = {
    text = (makeProfile "Shopping").desktop;
  };

  home.file.".local/bin/vivaldi-personal" = {
    executable = true;
    text = (makeProfile "Personal").wrapper;
  };
  home.file.".local/share/applications/vivaldi-personal.desktop" = {
    text = (makeProfile "Personal").desktop;
  };

  # === Один gocryptfs vault на все профили ===
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
    echo "❄️  Preparing Vivaldi Cryonic profiles..."
    mkdir -p ${vaultPath} ${mountPath}/{work,shopping,personal}
  '';
}