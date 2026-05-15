# vivaldi-cryonic/home.nix
{ pkgs, config, inputs, ... }:
let
  # Cryonic (приватный)
  vaultPathCryonic = "${config.home.homeDirectory}/Vaults/vivaldi-cryonic";
  configPathCryonic = "${config.home.homeDirectory}/.config/vivaldi-cryonic";

  # Stable (комфортный, но тоже зашифрованный)
  vaultPathStable = "${config.home.homeDirectory}/Vaults/vivaldi-stable";
  configPathStable = "${config.home.homeDirectory}/.config/vivaldi-stable";

  vivaldiCryonic = inputs.vivaldi-cryonic.packages.${pkgs.system}.vivaldi-cryonic;
  vivaldiStable = inputs.vivaldi-cryonic.packages.${pkgs.system}.vivaldi-stable;
in
{
  home.packages = [ pkgs.gocryptfs pkgs.fuse pkgs.sops ];

  # ==================== Desktop Entries ====================
  xdg.desktopEntries = {
    vivaldi-cryonic = {
      name = "Vivaldi Cryonic";
      comment = "Hardened & Encrypted";
      exec = builtins.concatStringsSep " " [
        "vivaldi-cryonic"
        "--user-data-dir=${configPathCryonic}"
        "%U"
      ];
      icon = "${config.home.homeDirectory}/Data/Flakes/vivaldi-cryonic/assets/icon2.png";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
    };

    vivaldi-stable = {
      name = "Vivaldi";
      comment = "Vivaldi Stable — Main";
      exec = builtins.concatStringsSep " " [
        "${vivaldiStable}/bin/vivaldi"
        "--user-data-dir=${configPathStable}"
        "%U"
      ];
      icon = "vivaldi";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
    };

    vivaldi-stable-old = {
      name = "Vivaldi (Old)";
      comment = "Vivaldi Stable — Old";
      exec = builtins.concatStringsSep " " [
        "${vivaldiStable}/bin/vivaldi"
        "--user-data-dir=${configPathStable}"
        "--profile-directory=Old"
        "%U"
      ];
      icon = "vivaldi";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
    };

    vivaldi-stable-work = {
      name = "Vivaldi (Work)";
      comment = "Vivaldi Stable — Work";
      exec = builtins.concatStringsSep " " [
        "${vivaldiStable}/bin/vivaldi"
        "--user-data-dir=${configPathStable}"
        "--profile-directory=Work"
        "%U"
      ];
      icon = "vivaldi";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
    };

    vivaldi-stable-shopping = {
      name = "Vivaldi (Shopping)";
      comment = "Vivaldi Stable — Shopping";
      exec = builtins.concatStringsSep " " [
        "${vivaldiStable}/bin/vivaldi"
        "--user-data-dir=${configPathStable}"
        "--profile-directory=Shopping"
        "%U"
      ];
      icon = "vivaldi";
      terminal = false;
      type = "Application";
      categories = [ "Network" "WebBrowser" ];
    };
  };

  # ==================== gocryptfs — Cryonic ====================
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
        mkdir -p ${vaultPathCryonic} ${configPathCryonic}
        if [ ! -f ${vaultPathCryonic}/gocryptfs.conf ]; then
          echo "❄️ First run: initializing Cryonic vault..."
          ${pkgs.gocryptfs}/bin/gocryptfs -init \
            -passfile ${config.sops.secrets."vivaldi-cryonic-passphrase".path} \
            ${vaultPathCryonic}
        fi
        ${pkgs.gocryptfs}/bin/gocryptfs \
          -passfile ${config.sops.secrets."vivaldi-cryonic-passphrase".path} \
          ${vaultPathCryonic} ${configPathCryonic}
      ''}";
      ExecStop = "${pkgs.fuse}/bin/fusermount -u ${configPathCryonic}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  # ==================== gocryptfs — Stable ====================
  systemd.user.services.vivaldi-stable-mount = {
    Unit = {
      Description = "Mount vivaldi-stable gocryptfs vault";
      After = [ "sops-nix.service" "graphical-session.target" ];
      Requires = [ "sops-nix.service" ];
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.writeShellScript "mount-vivaldi-stable" ''
        set -e
        mkdir -p ${vaultPathStable} ${configPathStable}
        if [ ! -f ${vaultPathStable}/gocryptfs.conf ]; then
          echo "❄️ First run: initializing Stable vault..."
          ${pkgs.gocryptfs}/bin/gocryptfs -init \
            -passfile ${config.sops.secrets."vivaldi-stable-passphrase".path} \
            ${vaultPathStable}
        fi
        ${pkgs.gocryptfs}/bin/gocryptfs \
          -passfile ${config.sops.secrets."vivaldi-stable-passphrase".path} \
          ${vaultPathStable} ${configPathStable}
      ''}";
      ExecStop = "${pkgs.fuse}/bin/fusermount -u ${configPathStable}";
    };
    Install.WantedBy = [ "default.target" ];
  };

  home.activation.setupBrowsers = ''
    echo "❄️ Preparing Vivaldi directories..."
    mkdir -p ${configPathCryonic} ${configPathStable}
    mkdir -p ${configPathStable}/Work ${configPathStable}/Shopping
  '';
}