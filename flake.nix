{
  description = "Hugo development and build environment for GitHub Pages";
  inputs = {
    nixpkgs.url = "git+https://github.com/nixos/nixpkgs?shallow=1&ref=nixpkgs-unstable";
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
    }:
    let
      allSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs allSystems;
    in
    {
      checks = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          pre-commit-check = git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt = {
                enable = true;
              };
              rumdl = {
                enable = true;
                name = "Markdown Lint Check (rumdl)";
                entry = "${pkgs.rumdl}/bin/rumdl check";
                types = [ "markdown" ];
                pass_filenames = false;
              };
              reuse = {
                enable = true;
                name = "SPDX License Check";
                entry = "${pkgs.reuse}/bin/reuse lint";
                pass_filenames = false;
              };
              gotmpl-lint = {
                enable = true;
                name = "Go Template Linter (djlint)";
                entry = "${pkgs.djlint}/bin/djlint --profile=golang --lint --ignore=H021";
                files = "\\.html$";
              };
            };
          };
        }
      );
      devShells = forAllSystems (
        system:
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
            # Make hugo, dependencies, custom scripts, and linters available in the shell
            packages = [
              pkgs.go
              pkgs.hugo
              pkgs.djlint
              pkgs.reuse
              pkgs.rumdl
              pkgs.nixfmt
              run-local-server
              build-github-pages
            ];
            # Path hijacking, pre-commit hook installation, and symlink creation
            shellHook = ''
              # 1. Install the pre-commit hooks
              ${self.checks.${system}.pre-commit-check.shellHook}
              # 2. Setup theme symlink
              echo "Setting up Hugo theme symlink..."
              mkdir -p test-site/themes
              # Use -snf to safely overwrite if a broken link exists
              ln -snf ../.. test-site/themes/floral-cities
              echo "Nix shell ready! Use 'run-local-server' to test locally."
            '';
          };
        }
      );
    };
}
