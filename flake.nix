{
  description = "SongBeamer Translation Flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs [ "x86_64-linux" "aarch64-linux" ];

      name = "songbeamer_translate";
      version = "0.1.0";
      image = {
        inherit name version;
        repository = "dawilky";
      };

      songbeamer-translate = pkgs: pkgs.buildNpmPackage {
        pname = "songbeamer-translate";
        inherit version;
        nodejs = pkgs.nodejs_24;
        npmDepsHash = "sha256-nIDY1vRB3xDcW1UlVTYTWaVjtOp8EL2KRlkx23Sm85w=";
        src = ./.;
        installPhase = ''
          runHook preInstall
          cp -r dist $out
          runHook postInstall
        '';
      };

      docker = pkgs:
        let
          nginxPort = "80";
          nginxConf = pkgs.writeText "nginx.conf" ''
            user nobody nobody;
            daemon off;
            error_log /dev/stdout info;
            pid /dev/null;
            events {}
            http {
              include ${pkgs.nginx}/conf/mime.types;
              access_log /dev/stdout;
              server_tokens off;
              server {
                listen ${nginxPort};
                index index.html;
                root /dist;
                include ${./nix/nginx-security.conf};
                location / {
                  try_files $uri $uri/ /index.html;
                }
                location /assets/ {
                  expires 1y;
                }
              }
            }
          '';
          # Real /dist directory (not a store symlink) so a favicon can be bind-mounted over it.
          dist = pkgs.runCommand "songbeamer-translate-dist" { } ''
            mkdir -p $out/dist
            cp -r ${self.packages.${pkgs.stdenv.hostPlatform.system}.songbeamer-translate}/. $out/dist/
          '';
        in
        { version ? image.version }: pkgs.dockerTools.buildLayeredImage {
          name = "${image.repository}/${image.name}";
          tag = "${version}";
          created = "now";

          contents = with pkgs; [
            coreutils
            bashInteractive
            curl
            fakeNss
            nginx
            dist
          ];

          extraCommands = ''
            mkdir -p tmp/nginx_client_body

            # nginx still tries to read this directory even if error_log
            # directive is specifying another file :/
            mkdir -p var/log/nginx
          '';

          config = {
            ExposedPorts = {
              "${nginxPort}" = { };
            };
            WorkingDir = "/dist";
            Healthcheck = {
              Test = [ "CMD" "curl" "-sSf" "http://localhost" ];
              Interval = 5 * 1000000000;
              Timeout = 2 * 1000000000;
              Retries = 2;
              StartPeriod = 2 * 1000000000;
            };
            Cmd = [ "nginx" "-c" nginxConf ];
          };
        };
    in
    {
      devShells = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              # Made available on the CLI
              nodejs_24
              nixpkgs-fmt
            ];

            # Keep @playwright/test in package.json pinned to this playwright-driver version.
            PLAYWRIGHT_BROWSERS_PATH = pkgs.playwright-driver.browsers;
            PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS = "true";

            shellHook = ''
              echo
              echo -e "\033[0;32mWelcome to the SongBeamer Translation development environment!\033[0m"
              echo
            '';
          };
        });

      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      packages = forAllSystems (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          songbeamer-translate = songbeamer-translate pkgs;
          default = docker pkgs { version = "latest"; };
          version = docker pkgs { };
        });

      nixosModules.default = import ./nix/module.nix self;

      checks = forAllSystems (system: {
        nixos = nixpkgs.legacyPackages.${system}.testers.runNixOSTest {
          name = "songbeamer-translate";
          nodes.machine = {
            imports = [ self.nixosModules.default ];
            services.songbeamer-translate = {
              enable = true;
              hostName = "localhost";
            };
          };
          testScript = ''
            machine.wait_for_unit("nginx.service")
            machine.wait_for_open_port(80)
            machine.succeed("curl -sSf http://localhost/ | grep -q '<div id=\"app\">'")
            machine.succeed("curl -sSf http://localhost/some/route | grep -q '<div id=\"app\">'")
            machine.succeed("curl -sSI http://localhost/ | grep -qi '^content-security-policy:'")
          '';
        };
      });
    };
}
