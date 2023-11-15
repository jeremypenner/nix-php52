# PHP 5.2.17 for NixOS

I host a community site that is based on Drupal 5, which can't be upgraded without throwing the whole thing in the bin and starting from scratch. 
Maybe someday I will do that, but in the meantime, people use it, and I have promised those people that I am not going to delete their stuff.

This repo now uses flakes but I haven't bothered to update this readme with usage information, sorry. Hopefully the flake itself is reasonable
documentation for what the repo provides. If anybody depends on this besides me, sorry I broke your site.

# Usage

I'm probably doing this wrong! I'm very new to NixOS. Bug reports or pull requests to make things more standard welcome. I think eventually I'll want this to 
be a "flake"? I haven't read up on those yet.

Right now I have this sitting in a directory called `php52` beside my nixops server definition. I use it like this:

```nix
{ config, pkgs, lib, ...}:
let
  php52 = import ./php52/default.nix { inherit pkgs; };
in
{
  require = [ ./php52/module.nix  ];

  services.php52-fpm.enable = true;
  services.nginx.enable = true;
  services.nginx.virtualHosts = {
    "old-php-site.com" = php52.vhost {
      root = "/var/www/old-php-site";
    };
    "old-drupal-site.com" = php52.vhostDrupal { 
      root = "/var/www/old-drupal-site";
    };
  };
}
```

`module.nix` defines an option to enable a systemd service that starts php-fpm on startup, before nginx starts. The `vhost` and `vhostDrupal` functions
take care of setting up secure default rules and connecting .php files to php-fpm. (`vhostDrupal` adds the rewrite rule that makes `/foo` internally map
to `/index.php?q=foo`.)

## Implementation notes

* I include source for all patches and modules directly because unsupported stuff that is a decade past end of life has a tendency to disappear from stable URLs.
* php52-backports-security-20130717.patch is required to build with modern libxml. It came from https://code.google.com/archive/p/php52-backports/downloads.
* I apply both the suhosin _patch_ and the suhosin _extension_, which are apparently totally separate things. The suhosin _extension_ is required for bcrypt 
  to work. I hacked my Drupal 5 installation to depend on bcrypt (I don't remember what it  was doing for password hashing exactly but it wasn't good). So I
  bundle it.
* I have no idea what I would need to do to patch PHP 5.2 so that you could actually used multiple extensions derived seperately in the nix store, so it's all 
  included in one giant derivation that does two builds. I also modify php.ini in place, so you really can't mess with it. 
* PHP 5.2 also makes hard assumptions a few places in the `configure` script that a library's headers and its binaries share a parent directory, which under
  `nixpkgs` is not true. I work around it by creating trivial derivations that merge the headers and binaries together for `libjpeg` and `libpng`. This is
  dumb, but it works.
* PHP 5.2 appears to bundle its own version of `libgd`, and depend on some of its internal functions that have disappeared in more modern incarnations -
  I gave up trying to tell it to use nixpkgs' version.
