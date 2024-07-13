{
  description = "TTS flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nix2container = {
      url = "github:nlewo/nix2container";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

  };

  outputs = { self, nixpkgs, flake-utils, nix2container }@inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs
            {
              inherit system;
              overlays = [
                (import ./overlays.nix {
                  inherit inputs;
                })
              ];
            };
          containerPkgs = nix2container.packages.${system};
        in
        {
          packages.tts-docker = containerPkgs.nix2container.buildImage
            {
              name = "tts-docker";
              tag = "latest";
              copyToRoot = pkgs.buildEnv {
                name = "image-root";
                paths = with pkgs; [
                  bash
                  cmake
                  stdenv.cc.cc.lib
                  python311Full
                  python311Packages.pip
                  python311Packages.numpy
                ];
                pathsToLink = [ "/bin" ];
              };
              config = {
                Cmd = [
                  "/bin/bash"
                ];
                ExposedPorts = {
                  "5002/tcp" = { };
                };
              };
            };



          devShell = pkgs.mkShell {

            nativeBuildInputs = with pkgs; [
              cmake
              stdenv.cc.cc.lib
              python311Full
              python311Packages.pip
              python311Packages.numpy
            ];

            buildInputs = with pkgs; [
            ];

            LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";

            shellHook = ''
              source .venv/bin/activate
            '';
          };
        }
      );
}
