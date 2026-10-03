# SongBeamer Translate

Creating translations for SongBeamer files can be quite annoying. If you use a translator like Google Translator you need to paste line by line into the SongBeamer file and can't paste the whole block.

To make it easier creating files with multiple languages I created this mini-tool. You can paste the text inside the input box and you get a translation by Google Translater inside the output box. In the final and third box the two languages are getting mixed with the switching-line machanism that you can directly copy into the SongBeamer-File.

The Application is written with german frontend text. There is also a light and a dark theme available.

A Screenshot of the Application:
![SongBeamer_Translator_Screenshot](https://github.com/da-wilky/songbeamer_translate/assets/34423885/edc866c7-a098-4640-8eaa-b95e1ba16318)

# Deployment

You can use the `docker-compose.yml` file to deploy the service. Just place it inside a folder and run `docker compose up -d`. Alternativly run the command `docker run --rm -p 8000:80 dawilky/songbeamer_translate`.

The service will be running on port `8000` of your machine. Customize the `docker-compose.yml` file to use a reverse proxy in front.

## NixOS

The flake provides a NixOS module that serves the app through `services.nginx`:

```nix
{
  inputs.songbeamer-translate.url = "github:da-wilky/songbeamer_translate";

  outputs = { nixpkgs, songbeamer-translate, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        songbeamer-translate.nixosModules.default
        {
          services.songbeamer-translate = {
            enable = true;
            hostName = "translate.example.com";
          };
          # TLS, basic auth etc. go on the generated virtual host:
          services.nginx.virtualHosts."translate.example.com" = {
            enableACME = true;
            forceSSL = true;
          };
          networking.firewall.allowedTCPPorts = [ 80 443 ];
        }
      ];
    };
  };
}
```

The static build alone is available as `nix build .#songbeamer-translate`; the Docker image as `nix build .#default`.

# Security

For production use you might put a reverse proxy in front of the service like `nginx` or `traefik`. You might also use some basic auth to authenticate requests.
