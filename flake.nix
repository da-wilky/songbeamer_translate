{
  description = "SongBeamer Translation Flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs = { self, nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };

      name = "songbeamer_translate";
      version = "0.1.0";
      image = {
        inherit name version;
        registry = "dr.swilk.eu";
        repository = "sw";
      };

      docker =
        let
          nginxPort = "80";
          nginxConf = pkgs.writeText "nginx.conf" ''
            user nobody nobody;
            daemon off;
            error_log /dev/stdout info;
            pid /dev/null;
            events {}
            http {
              include /conf/mime.types;
              access_log /dev/stdout;
              server {
                listen ${nginxPort};
                index index.html;
                location / {
                  root /dist;
                  try_files $uri $uri/ /index.html;
                }
              }
            }
          '';
        in
        { version ? image.version }: pkgs.dockerTools.buildLayeredImage {
          name = "${image.registry}/${image.repository}/${image.name}";
          tag = "${version}";
          created = "now";

          contents =
            let
              songbeamer-translate = pkgs.buildNpmPackage {
                name = "songbeamer-translate";
                buildInputs = with pkgs; [
                  nodejs_22
                ];
                npmDepsHash = "sha256-/W5N3G3fzsINNA3pKHthJFmZLZ+x/aANIDZDKb1agB8=";
                src = ./.;
                installPhase = ''
                  mkdir -p $out/dist
                  cp -r dist $out/
                '';
              };
            in
            with pkgs; [
              coreutils
              bashInteractive
              curl
              fakeNss
              nginx
              songbeamer-translate
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
              Interval = 60 * 1000000000;
              Timeout = 5 * 1000000000;
              Retries = 3;
              StartInterval = 3 * 1000000000;
            };
            Cmd = [ "nginx" "-c" nginxConf ];
          };
        };
    in
    {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          # Made available on the CLI
          nodejs_22
          nixpkgs-fmt
        ];

        shellHook = ''
          echo
          echo -e "\033[0;32mWelcome to the SongBeamer Translation development environment!\033[0m"
          echo
        '';
      };

      formatter.x86_64-linux = pkgs.nixpkgs-fmt;

      packages.x86_64-linux.default = docker { version = "latest"; };
      packages.x86_64-linux.version = docker { };
    };
}

