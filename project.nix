{ config, nix-haskell-patches, ... }:

let nix-thunk = config.importing.nix-thunk;
    thunks = with nix-thunk; mapSubdirectories thunkSource ./thunks;
    #
    nixos-24_11 = import thunks."nixos-24.11" {};

in {
  name = "reflex-dom";
  src = ./.;
  compiler-nix-name = "ghc914";

  overrides = [
    ({ pkgs, ... }: {
      packages = {
        reflex-dom-core.components = {
          tests = {
            gc.build-tools = with nixos-24_11; [
              chromium
            ];
            hydration.build-tools = with nixos-24_11; [
              chromium
              selenium-server-standalone
            ];
          };
        };
      };
    })
  ];

  shell = {
    crossPlatforms = ps: with ps; [ ghcjs wasi32 ];
    withHoogle = true;
  };

}
