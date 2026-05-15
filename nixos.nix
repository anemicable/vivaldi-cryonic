{ config, pkgs, inputs, ... }:
{
  system.stateVersion = "26.05";

  # Sops (уже работает)
  sops = {
    defaultSopsFile = "${inputs.my-secrets}/secrets-backup.yaml";
    defaultSopsFormat = "yaml";
    age.keyFile = "/home/mistflow/.config/sops/age/keys.txt";
    secrets."vivaldi-cryonic-passphrase" = { };
  };

  # 🔥 Отличная блокировка телеметрии Vivaldi
  networking.extraHosts = ''
    0.0.0.0 mimir.vivaldi.com
    0.0.0.0 updates.vivaldi.com
    0.0.0.0 telemetry.vivaldi.com
    0.0.0.0 vivaldi.com
  '';

  # Разрешаем unfree-пакеты (лучше так, чем в flake)
  # nixpkgs.config.allowUnfree = true;

  # Можно включить (рекомендую)
  networking.firewall.enable = true;
}