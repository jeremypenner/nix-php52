packages: { config, lib, pkgs, ...}@args:
with lib;
let
    cfg = config.services.php52-fpm;
in {
    options.services.php52-fpm = {
        enable = mkOption {
            type = types.bool;
            default = false;
            description = ''
                If enabled, NixOS will start a PHP 5.2 FastCGI daemon in the background.
            '';
        };
    };

    config = {
        systemd.services.php52-fpm = mkIf cfg.enable {
            wantedBy = [ "multi-user.target" ];
            before = [ "nginx.service" ];
            environment = {
                PHP_FCGI_CHILDREN = "4";
                PHP_FCGI_MAX_REQUESTS = "5000";
            };
            serviceConfig = {
                Type = "forking";
                PIDFile = "/run/php52-fpm/php-fpm.pid";
                ExecStart = "${packages."${pkgs.system}".default}/bin/php-cgi -x";
                User = "nginx";
                Group = "nginx";
                RuntimeDirectory = "php52-fpm";
                LogsDirectory = "php52-fpm";
                Restart = "always";
            };
        };
    };
}