{
  inputs =
    {
      nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
      ps-tools.follows = "purs-nix/ps-tools";
      purs-nix.url = "github:purs-nix/purs-nix/ps-0.15";
      utils.url = "github:numtide/flake-utils";
    };

  outputs = { nixpkgs, utils, ... }@inputs:
    utils.lib.eachSystem [ "x86_64-linux" "x86_64-darwin" ]
      (system:
        let
          name = "Ch_28";
          pkgs = nixpkgs.legacyPackages.${system};
          ps-tools = inputs.ps-tools.legacyPackages.${system};
          purs-nix = inputs.purs-nix { inherit system; };

          ps =
            purs-nix.purs
              {
                dependencies =
                  with purs-nix.ps-pkgs;
                  [ 
                    console
                    effect
                    prelude
                    httpurple
                    psci-support
                    aff
                    datetime
                  ];

                dir = ./.;
              };
          ps-command = ps.command { };
          purs-watch = pkgs.writeShellApplication {
            name = "purs-watch";
            runtimeInputs = with pkgs; [ entr ps-command ];
            text = "find src | entr -s 'echo building && purs-nix compile'";
          };
          vite = pkgs.writeShellApplication {
            name = "vite";
            runtimeInputs = with pkgs; [ nodejs ];
            text = "npx vite --open dev/index.html";
          };
          dev = pkgs.writeShellApplication {
            name = "dev";
            runtimeInputs = with pkgs; [ concurrently ];
            text = "concurrently purs-watch vite";
          };
        in
        {
          # packages.default = ps.modules.Main.bundle { };
          packages = with ps; {
            default = ps.modules.Main.bundle {};
            bundle = bundle {};
            output = output {};
          };
          bundle.esbuild = {format = "iife";};
          # checks.default = checks;

          devShells.default =
            pkgs.mkShell
              {
                inherit name;
                packages =
                  with pkgs;
                  [
                    ps-tools.for-0_15.purescript-language-server
                    ps-command
                    purs-nix.purescript
                    purs-watch
                    vite
                    dev
                    httpie
                  ];
              };
        }
      );
}