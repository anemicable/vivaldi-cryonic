# vivaldi-cryonic/home.nix
{ pkgs, config, ... }:
let
  vaultPath = "${config.home.homeDirectory}/Vaults/vivaldi-cryonic";
  configPath = "${config.home.homeDirectory}/.config/vivaldi-cryonic";  # ← монтируем сюда
in
{
  home.packages = [ pkgs.gocryptfs pkgs.fuse pkgs.sops ];

  # ==================== Desktop Entries ====================
  xdg.desktopEntries = {
    vivaldi-cryonic = {
      name = "Vivaldi Cryonic";
      comment = "Hardened Vivaldi";
      exec = "vivaldi-cryonic --user-data-dir=${configPath} %U";
      icon = "${config.home.homeDirectory}/Data/Flakes/vivaldi-cryonic/assets/icon2.png";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
    };

    vivaldi-cryonic-personal = {
      name = "Vivaldi Cryonic (Personal)";
      comment = "Hardened Vivaldi (Personal)";
      exec = "vivaldi-cryonic --user-data-dir=${configPath} %U --profile-directory=Personal";
      icon = "${config.home.homeDirectory}/Data/Flakes/vivaldi-cryonic/assets/icon2.png";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
    };

    vivaldi-cryonic-work = {
      name = "Vivaldi Cryonic (Work)";
      comment = "Hardened Vivaldi — Work profile";
      exec = "vivaldi-cryonic --user-data-dir=${configPath} --profile-directory=Work %U";
      icon = "${config.home.homeDirectory}/Data/Flakes/vivaldi-cryonic/assets/icon2.png";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
    };

    vivaldi-cryonic-shopping = {
      name = "Vivaldi Cryonic (Shopping)";
      comment = "Hardened Vivaldi — Shopping profile";
      exec = "vivaldi-cryonic --user-data-dir=${configPath} --profile-directory=Shopping %U";
      icon = "${config.home.homeDirectory}/Data/Flakes/vivaldi-cryonic/assets/icon-shopping.png";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
    };
  };

  # ==================== gocryptfs Mount ====================
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
        mkdir -p ${vaultPath} ${configPath}

        if [ ! -f ${vaultPath}/gocryptfs.conf ]; then
          echo "❄️ First run: initializing gocryptfs vault..."
          ${pkgs.gocryptfs}/bin/gocryptfs -init \
            -passfile ${config.sops.secrets."vivaldi-cryonic-passphrase".path} \
            ${vaultPath}
        fi

        ${pkgs.gocryptfs}/bin/gocryptfs \
          -passfile ${config.sops.secrets."vivaldi-cryonic-passphrase".path} \
          ${vaultPath} ${configPath}
      ''}";

      ExecStop = "${pkgs.fuse}/bin/fusermount -u ${configPath}";
    };

    Install.WantedBy = [ "default.target" ];
  };

  # Создаём папку на всякий случай (хотя gocryptfs сам создаст)
  home.activation.cryonicSetup = ''
    echo "❄️ Preparing Vivaldi Cryonic encrypted config..."
    mkdir -p ${configPath}
  '';
}