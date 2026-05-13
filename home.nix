# home.nix
{ pkgs, config, ... }:
let
  # Пути к unpacked расширениям (создай папки и скачай туда расширения)
  ublockPath = "${config.home.homeDirectory}/.config/vivaldi/extensions/uBlock0";
  canvasBlockerPath = "${config.home.homeDirectory}/.config/vivaldi/extensions/CanvasBlocker";

in {
  home.packages = [ pkgs.vivaldiCryonic ];

  # === Автоматическое создание hardened Preferences ===
  home.activation.cryonicVivaldiPreferences = ''
    echo "❄️  Applying Vivaldi Cryonic Preferences..."
    mkdir -p $HOME/.config/vivaldi/Default

    cat > $HOME/.config/vivaldi/Default/Preferences << 'EOF'
{
  "profile": {
    "content_settings": {
      "exceptions": {
        "cookies": {}
      }
    }
  },
  "vivaldi": {
    "tracker_blocker": {
      "default_level": 2   // 0 = No Blocking, 1 = Block Trackers, 2 = Block Trackers and Ads
    }
  },
  "browser": {
    "clear_data_on_exit": true
  },
  "privacy": {
    "third_party_cookie_blocking": 2,   // Strict
    "block_hyperlink_audit": true,
    "web_rtc_multiple_routes_enabled": false
  },
  "safebrowsing": {
    "enabled": false
  }
}
EOF
  '';

  # === Unpacked extensions ===
  home.file.".config/vivaldi/extensions/uBlock0" = {
    source = pkgs.fetchgit {
      url = "https://github.com/gorhill/uBlock";  # или локальный путь
      rev = "master";  # лучше зафиксировать ревизию
      sha256 = "";     # nix-build подскажет
    };
    recursive = true;
  };

  home.file.".config/vivaldi/extensions/CanvasBlocker" = {
    source = pkgs.fetchgit {
      url = "https://github.com/kkapsner/CanvasBlocker";
      rev = "master";
      sha256 = ""; 
    };
    recursive = true;
  };

  # === Wrapper с firejail (рекомендую начать с него) ===
  home.file.".local/bin/vivaldi-cryonic" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      echo "❄️  Launching Vivaldi Cryonic in firejail..."
      exec ${pkgs.firejail}/bin/firejail \
        --netfilter \
        --caps.drop=all \
        --nonewprivs \
        --noroot \
        --seccomp \
        --private-cache \
        --private-tmp \
        --whitelist=$HOME/.config/vivaldi \
        --whitelist=$HOME/Downloads \
        ${pkgs.vivaldiCryonic}/bin/vivaldi "$@"
    '';
  };

  # Альтернатива: bubblewrap (bwrap) — если предпочитаешь его
  # home.file.".local/bin/vivaldi-cryonic-bwrap" = { ... };

  sops.secrets."vivaldi-cryonic-passphrase" = {
    path = "${config.xdg.runtimeDir}/secrets/vivaldi-cryonic-passphrase";
  };
}