{
  description = "Huw's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, home-manager, agenix, nur, ... }:
  let
    system = "x86_64-linux";
    pkgs   = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations.framework-13 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        # Hardware — swap for the AI 300 module once it lands in nixos-hardware
        # nixos-hardware.nixosModules.framework-13-7040-amd
        # Track: https://github.com/NixOS/nixos-hardware

        ./hosts/framework-13/configuration.nix

        # NUR overlay — provides pkgs.nur.repos.rycee.firefox-addons
        { nixpkgs.overlays = [ nur.overlay ]; }

        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs    = true;
          home-manager.useUserPackages  = true;
          home-manager.users.huw        = import ./home/huw;
        }

        agenix.nixosModules.default
      ];
    };

    # nix develop .#ai  — or add `use flake .#ai` to an .envrc
    devShells.${system}.ai = import ./modules/development/ai-shell.nix { inherit pkgs; };
  };
}
