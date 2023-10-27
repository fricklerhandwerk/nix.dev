{
  description = "nix.dev static website";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nix_2-13.url = "github:NixOS/nix/2.13-maintenance";
  inputs.nix_2-18.url = "github:NixOS/nix/2.18-maintenance";

  outputs = { self, nixpkgs, flake-utils, nix_2-13, nix_2-18 }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            # Add sphinx-sitemap from an overlay until
            # it becomes available from nixpkgs-unstable
            (import ./overlay.nix)
          ];
        };
        devmode =
          let
            pythonEnvironment = pkgs.python310.withPackages (ps: with ps; [
              livereload
            ]);
            script = ''
              from livereload import Server, shell

              server = Server()

              build_docs = shell("nix build")

              print("Doing an initial build of the docs...")
              build_docs()

              server.watch("source/*", build_docs)
              server.watch("source/**/*", build_docs)
              server.watch("_templates/*.html", build_docs)
              server.serve(root="result/")
            '';
          in
          pkgs.writeShellApplication {
            name = "devmode";
            runtimeInputs = [ pythonEnvironment ];
            text = ''
              python ${pkgs.writeText "live.py" script}
            '';
          };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          name = "nix-dev";
          src = self;
          nativeBuildInputs = with pkgs.python310.pkgs; [
            linkify-it-py
            myst-parser
            sphinx
            sphinx-book-theme
            sphinx-copybutton
            sphinx-design
            sphinx-notfound-page
            sphinx-sitemap
          ];
          buildPhase = ''
            make html
          '';
          installPhase =
            let
              nix_2-13-doc = nix_2-13.packages.${system}.nix.doc;
              nix_2-18-doc = nix_2-18.packages.${system}.nix.doc;
            in
            ''
              mkdir -p $out/manual/nix/{2.13,2.18}
              cp -R ${nix_2-13-doc}/share/doc/nix/manual/* $out/manual/nix/2.13
              cp -R ${nix_2-18-doc}/share/doc/nix/manual/* $out/manual/nix/2.18
              cp -R build/html/* $out/
            '';
        };

        devShells.default = pkgs.mkShell {
          inputsFrom = [ self.packages.${system}.default ];
          packages = with pkgs.python310.pkgs; [
            black
            devmode
          ];
        };
      }
    );
}
