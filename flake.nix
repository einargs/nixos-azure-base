{
  description = "Tool for doctors to summarize doctor-patient conversations";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.05";
    nixos-generators = {
      url = "github:nix-community/nixos-generators";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  nixConfig = {
    bash-prompt = ''\[\033[1;32m\][\[\e]0;\u@\h: \w\a\]dev-shell:\w]\$\[\033[0m\] '';
  };

  outputs = { self, nixpkgs, nixos-generators }: 
  let system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        config.permittedInsecurePackages = [
          # "openssl-1.1.1v"
          # "openssl-1.1.1w"
        ];
      };
      azure-image = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
        };
        modules = [
          nixos-generators.nixosModules.all-formats
          ./vm.nix
        ];
      };
  in {

    # To get an image we can deploy to azure do:
    # nix build .#nixosConfigurations.my-machine.config.formats.azure
    nixosConfigurations.azure-vm = azure-image;
    # To rebuild once we're inside the machine we can do
    # sudo nixos-rebuild switch --flake .#azure-vm

    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = with pkgs; [
        azure-cli
      ];
      src = [
        ./flake.nix
        ./flake.lock
      ];
    };
  };
}
