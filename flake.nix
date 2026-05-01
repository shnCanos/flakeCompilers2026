{
  description = "Compiler project 2026 flake IST";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        libcdkSource = ./Libcdk21-202604232308.tar.bz2;
        librtsSource = ./Librts7-202604232308.tar.bz2;
      in
      {
        packages = {
          libcdk = pkgs.stdenv.mkDerivation {
            name = "libcdk";
            buildInputs = with pkgs; [
              gnumake
              gcc
              python3
              doxygen
              # graphviz
            ];

            src = libcdkSource;
            postPatch = ''
              patchShebangs ./bin/cdk
              substituteInPlace Makefile --replace-fail "/usr" ""
              substituteInPlace Makefile --replace-fail "\''${HOME}/compiladores/root" "$out"
            '';
            preBuild = ''
              # HACK: It tries to create .config/cdk.init
              export HOME="$(mktemp -d)"
            '';
          };
          librts = pkgs.stdenv.mkDerivation {
            name = "librts";
            buildInputs = with pkgs; [
              gnumake
              gcc
              doxygen
              yasm
              # graphviz
            ];

            src = librtsSource;
            postPatch = ''
              substituteInPlace Makefile --replace-fail "/usr" ""
              substituteInPlace Makefile --replace-fail "\''${HOME}/compiladores/root" "$out"
            '';
          };

          applyPatches = pkgs.writeShellApplication {
            name = "applyPatches";
            runtimeInputs = [ pkgs.gnused ];
            text = ''
              set -euxo pipefail
              # shellcheck disable=SC2016
              sed -i 's|CDK *= *\$(CDK_BIN_DIR)/cdk|CDK = ${self.packages.${system}.libcdk}/bin/cdk|' Makefile
              # Libraries are already installed
              # shellcheck disable=SC2016
              sed -i 's|-I\$(CDK_INC_DIR)||g' Makefile
              # shellcheck disable=SC2016
              sed -i 's|-L\$(CDK_LIB_DIR)||g' Makefile
            '';
          };
        };
        devShells.default = pkgs.mkShell {
          packages =
            with pkgs;
            [
              # Personal preference
              clang-tools
              binutils
              gdb
              valgrind
              bear

              gcc
              flex
              bison
              yasm
              gnumake
              libxml2
            ]
            ++ (with self.packages.${system}; [
              libcdk
              librts
            ]);

          shellHook = "";
        };
      }
    );
}
