{ pkgs ? import <nixpkgs> {}, lib ? import <nixpkgs/lib>, ... }:
with pkgs; let
  mergedLib = lib: name:
    derivation {
        inherit name coreutils;
        system = builtins.currentSystem;
        builder = "${bash}/bin/bash";
        args = [ ./merge.sh "${lib.out}/*" "${lib.dev}/*" ];
    };
  m_libjpeg = mergedLib libjpeg "m_libjpeg";
  m_libpng = mergedLib libpng "m_libpng";
  php52 = stdenv.mkDerivation {
    name = "php52";
    src = ./php-5.2.17.tar.bz2;
    patches = [ ./php52-backports-security-20130717.patch ./php-5.2.17-fpm.patch ./suhosin-patch-5.2.16-0.9.7.patch ];
    configureFlags = [ 
        "--enable-fastcgi"
        "--with-zlib=${zlib.dev}" 
        "--with-bz2=${bzip2.dev}" 
        "--enable-calendar"
        "--with-curl=${curl.dev}"
        "--enable-exif" 
        "--with-gd"
        "--with-mcrypt=${libmcrypt}" 
        "--with-mysql=${mysql57}" 
        "--enable-zip" 
        "--with-pear" 
        "--enable-force-cgi-redirect" 
        "--enable-debug" 
        "--enable-mbstring"
        "--enable-fastcgi"
        "--with-fpm-log=/var/log/php52-fpm/php-fpm.log"
        "--with-fpm-pid=/run/php52-fpm/php-fpm.pid"
        "--enable-fpm"
        "--with-libxml-dir=${libxml2.dev}"
        "--with-jpeg-dir=${m_libjpeg}"
        "--with-png-dir=${m_libpng}"
    ];
    postInstall = ''
      cp ./php.ini-recommended "$out/lib/php.ini"
      tar xf ${./suhosin-0.9.31.tgz}
      cd suhosin-0.9.31
      PATH="$out/bin:$PATH" phpize
      PATH="$out/bin:$PATH" ./configure --enable-suhosin
      make install
      cd ..
      sed -i 's:^extension_dir = .*:extension_dir = "'$("$out/bin/php-config" --extension-dir)'":' "$out/lib/php.ini"
      echo "extension=suhosin.so" >> "$out/lib/php.ini"
    '';
    buildInputs = [ zlib bzip2 curlFull libmcrypt mysql57 libxml2 lzma m_libjpeg m_libpng autoconf automake ];
  };
in
  php52 // rec {
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
        "~ (^|/)\\." = { return = "403"; };
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
  }