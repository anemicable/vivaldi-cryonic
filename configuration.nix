# configuration.nix
{ config, pkgs, inputs, ... }:
{
  # === Базовые настройки ===
  system.stateVersion = "26.05";  # или твоя версия

  sops = {
    defaultSopsFile = "${inputs.my-secrets}/secrets-backup.yaml";  # ← работает!
    defaultSopsFormat = "yaml";

    age.keyFile = "/home/mistflow/.config/sops/age/keys.txt";

    # Если хочешь, можно указать конкретный секрет здесь
    secrets."vivaldi-cryonic-passphrase" = { };
  };

  # Блокировка телеметрии Vivaldi на уровне системы (самое важное)
  networking.extraHosts = ''
    0.0.0.0 mimir.vivaldi.com
    0.0.0.0 updates.vivaldi.com
    0.0.0.0 telemetry.vivaldi.com
    0.0.0.0 vivaldi.com      # если хочешь совсем жёстко
  '';

  # Разрешаем unfree (vivaldi proprietary)
  nixpkgs.config.allowUnfree = true;

  # Опционально: firewall + nftables
  networking.firewall.enable = true;

  # Пример: если хочешь firejail для Vivaldi
  #programs.firejail.enable = true;
}