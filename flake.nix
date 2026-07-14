{
  description = "Hugo development and build environment for GitHub Pages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      allSystems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs allSystems;
    in
    {
      devShells = forAllSystems (system:
        let
          siteDir = "$(pwd)/test-site";
          pkgs = nixpkgs.legacyPackages.${system};

          # Local dev server script
          run-local-server = pkgs.writeShellScriptBin "run-local-server" ''
            hugo server -DF --noHTTPCache -s "${siteDir}" --disableFastRender
          '';

          # Build script for GitHub Actions
          build-github-pages = pkgs.writeShellScriptBin "build-github-pages" ''
            hugo -F --gc --minify -s "${siteDir}" -d "${siteDir}/output" "$@"
          '';
        in
        {
          default = pkgs.mkShell {
            # Make hugo and our custom scripts available in the shell
            packages = [
              pkgs.hugo
              run-local-server
              build-github-pages
            ];

            # Path hijacking and symlink creation
            shellHook = ''
              echo "Setting up Hugo theme symlink..."
              mkdir -p test-site/themes
              
              # Use -snf to safely overwrite if a broken link exists
              ln -snf ../.. test-site/themes/floral-cities
              
              echo "Nix shell ready! Use 'run-local-server' to test locally."
            '';
          };
        });
    };
}