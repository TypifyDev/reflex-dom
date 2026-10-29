{ system ? builtins.currentSystem }:
let
  nixHaskellPath = ./thunks/nix-haskell;
  nixHaskellSrc = if builtins.pathExists (nixHaskellPath + "/thunk.nix")
    then import (nixHaskellPath + "/thunk.nix")
    else nixHaskellPath;
  nix-haskell = import nixHaskellSrc { inherit system; };
  project = import ./project.nix;
in (nix-haskell project).haskell-nix.project
