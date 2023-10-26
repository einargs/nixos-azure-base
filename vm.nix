{ pkgs, modulesPath, ... }: {
  imports = [
    # For local testing uncomment this and comment out the azure image.
    # ./local.nix
    "${modulesPath}/virtualisation/azure-image.nix"
  ];
  nixpkgs.config.permittedInsecurePackages = [
    # Old versions of openssl some things still need
    # "openssl-1.1.1w"
    # "openssl-1.1.1v"
  ];
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [
    git
    vim
    tmux
  ];
  networking.firewall.allowedTCPPorts = [ 80 443 8080 ];
  users.mutableUsers = false;
  networking.hostName = "backend";

  users.users.hack = {
    isNormalUser = true;
    home = "/home/hack";
    description = "admin";
    extraGroups =
      [ "wheel" # users in wheel are allowed to use sudo
        "disk" "audio" "video" "networkmanager" "systemd-journal"
      ];
    # If you disable this it requires 
    hashedPassword = "$y$j9T$vsRtWjpE4252XW/6CASe3/$wptn/nGTeXFNI1jYEkx1ejVlz6DzoYSNMWDFfhLUF18";
  };
  system.stateVersion = "23.05";
  services.openssh = {
    enable = true;
    # This requires you to use an ssh key. Not great for when you're in a
    # hackathon.
    # settings.PasswordAuthentication = false;
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "einargs@gmail.com";
  };
  services.nginx = {
    enable = true;
    appendHttpConfig = ''
      upstream backend {
        server 127.0.0.1:8080;
      }
    '';
    virtualHosts = {
      "vandyhacksx.einargs.dev" = {
        # We'll turn this on once we have a certificate
        enableACME = true;
        forceSSL = true;
        locations."/" = {
          # We're just going to have the static files uploaded to a folder
          # instead of trying to package them in while building.
          root = "/www/static";
          # priority = 100;
        };
        # In case we need socket.io
        locations."/socket.io/" = {
          # these duplicate some of the stuff in extraConfig
          # recommendedProxySettings = true;
          # proxyWebsockets = true;
          # priority = 50;
          proxyPass = "http://backend"; # The socket.io path is kept
          extraConfig = ''
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header Host $host;

            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
          '';
        };
      };
    };
  };
}
