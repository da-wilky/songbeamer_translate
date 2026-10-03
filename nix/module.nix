self:
{ config, lib, pkgs, ... }:
let
  cfg = config.services.songbeamer-translate;
in
{
  options.services.songbeamer-translate = {
    enable = lib.mkEnableOption "SongBeamer Translate, served by nginx";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.songbeamer-translate;
      defaultText = lib.literalExpression "songbeamer-translate.packages.\${system}.songbeamer-translate";
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      example = "translate.example.com";
      description = ''
        nginx virtual host serving the app. Configure TLS, ports or basic auth via
        `services.nginx.virtualHosts.<hostName>`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx = {
      enable = true;
      virtualHosts.${cfg.hostName} = {
        root = cfg.package;
        extraConfig = "include ${./nginx-security.conf};";
        locations."/".tryFiles = "$uri $uri/ /index.html";
        locations."/assets/".extraConfig = "expires 1y;";
      };
    };
  };
}
