{
  description = "philip-amendolia resume site";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs =
    { self, nixpkgs }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ] (
          system: f nixpkgs.legacyPackages.${system}
        );
    in
    {
      packages = forAllSystems (pkgs: {
        default = pkgs.runCommand "philip-amendolia-resume" { } ''
          cp ${./index.html} $out
        '';
      });

      formatter = forAllSystems (pkgs: pkgs.nixfmt);

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.browser-sync
            pkgs.entr
            pkgs.prettier
            (pkgs.writeShellScriptBin "dev" ''
              set -euo pipefail
              rebuild() {
                nix build --no-link --print-out-paths path:$PWD 2>/dev/null > hash.txt
              }
              rebuild
              echo index.html | entr -s 'nix build --no-link --print-out-paths path:$PWD 2>/dev/null > hash.txt' &
              ENTR_PID=$!
              trap "kill $ENTR_PID 2>/dev/null" EXIT
              browser-sync start --server --files 'index.html,hash.txt' --no-notify --port 3000
            '')
          ];
          shellHook = ''
                        echo "dev → http://localhost:3000"
                        mkdir -p .git/hooks
                        cat > .git/hooks/pre-commit <<'EOF'
            #!/usr/bin/env bash
            prettier --write index.html
            git add index.html
            EOF
                        chmod +x .git/hooks/pre-commit
          '';
        };
      });
    };
}
