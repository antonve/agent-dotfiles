{
  description = "Dotfiles for Debian cloud agent boxes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    herdr.url = "github:ogulcancelik/herdr/v0.8.2";
    treehouse.url = "github:kunchenguid/treehouse";
  };

  outputs = { self, nixpkgs, home-manager, herdr, treehouse }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      mkHome = system: home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
        modules = [ ./home.nix ];
        extraSpecialArgs = { inherit herdr treehouse; };
      };
    in {
      # bootstrap.sh picks the right one via uname -m
      homeConfigurations = nixpkgs.lib.genAttrs (map (s: "agent-${s}") systems)
        (name: mkHome (nixpkgs.lib.removePrefix "agent-" name));

      # so bootstrap.sh can `nix run <repo>#home-manager` at the pinned version
      packages = nixpkgs.lib.genAttrs systems (system: {
        home-manager = home-manager.packages.${system}.home-manager;
      });
    };
}
