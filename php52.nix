{ pkgs, ... }:
let mergedLib = lib: name:
        derivation {
            inherit name;
            system = pkgs.system;
            coreutils = pkgs.coreutils;
            builder = "${pkgs.bash}/bin/bash";
            args = [ ./merge.sh "${lib.out}/*" "${lib.dev}/*" ];
        };
    m_libjpeg = mergedLib pkgs.libjpeg "m_libjpeg";
    m_libpng = mergedLib pkgs.libpng "m_libpng";
in with pkgs; stdenv.mkDerivation {
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
          sed -i 's:^upload_max_filesize = .*:upload_max_filesize = 200M:' "$out/lib/php.ini"
          sed -i 's:^post_max_size = .*:post_max_size = 200M:' "$out/lib/php.ini"
          echo "extension=suhosin.so" >> "$out/lib/php.ini"
          echo "sendmail_path=/run/wrappers/bin/sendmail -t -i" >> "$out/lib/php.ini"
        '';
        buildInputs = [ zlib bzip2 curlFull libmcrypt mysql57 libxml2 lzma m_libjpeg m_libpng autoconf automake ];
    }
