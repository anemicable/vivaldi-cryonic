# vivaldi-cryonic/home.nix
{ pkgs, config, ... }:

let
  vaultPath   = "${config.home.homeDirectory}/Vaults/vivaldi-cryonic";
  mountPath   = "${config.home.homeDirectory}/.config/vivaldi-cryonic";
  profilePath = "${mountPath}/personal";   # твоя текущая папка
in
{
  home.packages = [ pkgs.gocryptfs pkgs.fuse pkgs.sops ];

  # Иконка в меню
  xdg.desktopEntries = {
    vivaldi-cryonic = {
      name = "Vivaldi Cryonic";
      comment = "Hardened Vivaldi";
      exec = "vivaldi-cryonic %U";        
      icon = "${config.home.homeDirectory}/Data/Flakes/vivaldi-cryonic/assets/icon2.png";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
   };
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