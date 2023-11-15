pkgs: let
  lib = pkgs.lib;
  vhost = cfg: lib.recursiveUpdate {
    extraConfig = ''
      client_max_body_size 200m;
      index index.php index.html index.htm;
    '' + cfg.extraConfig or "";
    locations = {
      "/favicon.ico" = {
        extraConfig = ''
          log_not_found off;
          access_log off;
        '';
      };
      "/robots.txt" = {
        extraConfig = ''
          allow all;
          log_not_found off;
          access_log off;
        '';
      };
      "~ \\..*/.*\\.php$" = { return = "403"; };
      "~ ^/sites/.*/private/" = { return = "403"; };

      # Block access to "hidden" files and directories whose names begin with a
      # period. This includes directories used by version control systems such
      # as Subversion or Git to store control files.
      "~ (^|/)\\.(?!well-known/)" = { return = "403"; };
      "~ \\.php$" = {
        extraConfig = ''
          client_max_body_size 200m;

          fastcgi_split_path_info ^(.+\.php)(/.+)$;
          if (!-f $document_root$fastcgi_script_name) {
              return 404;
          }
  
          fastcgi_pass 127.0.0.1:9000;
          fastcgi_index index.php;
          include ${pkgs.nginx}/conf/fastcgi.conf;
          fastcgi_param HTTP_PROXY "";
        '';
      };
      "~ /\.ht" = {
        extraConfig = ''
          # deny access to .htaccess files, if Apache's document root
          # concurs with nginx's one
          deny all;
        '';
      };
    };
  } (builtins.removeAttrs cfg [ "extraConfig" ]);
  vhostDrupal = cfg: vhost (lib.recursiveUpdate cfg {
    locations = {
      "/" = { tryFiles = "$uri @rewrite"; };
      "@rewrite" = { 
        extraConfig = ''
          # For Drupal 6 and bwlow:
          # Some modules enforce no slash (/) at the end of the URL
          # Else this rewrite block wouldn't be needed (GlobalRedirect)
          rewrite ^/(.*)$ /index.php?q=$1;
        '';
      };
    };
  });
in 
{
  inherit vhost vhostDrupal; 
}
