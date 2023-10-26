{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  networking.firewall.enable = false;
  # When we're locally virtualizing the machine, forward ports so we can test
  # the server
  virtualisation.forwardPorts = [
    { from = "host"; host.port = 8000; guest.port = 80; }
    { from = "host"; host.port = 8443; guest.port = 443; }
    { from = "host"; host.port = 8022; guest.port = 22; }
    { from = "host"; host.port = 8001; guest.port = 8080; }
  ];
  # Here we have nginx use some self signed certificates for testing.
  services.nginx = {
    virtualHosts = {
      "vandyhacksx.einargs.dev" = {
        sslCertificateKey = "${./selfsigned.key}";
        sslCertificate = "${./selfsigned.crt}";
      };
    };
  };
}
