{ pkgs, ... }:
let
  inherit (pkgs) lib;
  networks = [ "webnet" ];
in {
  config.project.name = "openfoodfacts-server";
  config.docker-compose.raw = {
    "volumes" = [ "dbdata:" ];
  };
  config.services = {

    mongodb.service = {
      image = "mongo:4.4";
      volumes = [ "dbdata:/var/lib/mongodb" ];
      inherit networks;
    };

    memcached.service = {
      image = "memcached:1.6-alpine";
      inherit networks;
    };

    postgres.service = {
      image = "postgres:12-alpine";
      volumes = [ "pgdata:/var/lib/postgresql/data" ];
      environment.POSTGRES_PASSWORD = "productopener";
      environment.POSTGRES_USER = "productopener";
      environment.POSTGRES_DB = "minion";
      inherit networks;
    };

    backend = {
      nixos = {
        useSystemd = true;
        configuration = {
          boot.tmpOnTmpfs = true;
          services.httpd = {
            enable = true;
            # hostName = "productopener";
            adminAddr = "productopener@example.org";
          };
          # Copied over from the examples
          # Not sure as to the reason why these are necessary
          services.nscd.enable = false;
          system.nssModules = lib.mkForce [ ];
        };
      };
      service = {
        depends_on = [ "mongodb" "memcached" "postgres" ];
        volumes = [
          "podata:/mnt/podata"
          "product_images:/opt/product-opener/html/images/products"
          "html_data:/opt/product-opener/html/data"
          "${toString ./.}/backend-dev/conf/Config.pm:/opt/product-opener/lib/ProductOpener/Config.pm"
          "${toString ./.}/backend-dev/conf/Config2.pm:/opt/product-opener/lib/ProductOpener/Config2.pm"
          "${toString ./.}/backend-dev/conf/log.conf:/mnt/podata/log.conf"
          "${toString ./.}/backend-dev/conf/minion_log.conf:/mnt/podata/minion_log.conf"
          "${toString ./.}/backend-dev/conf/apache.conf:/etc/apache2/sites-enabled/product-opener.conf"
          "${toString ./.}/backend-dev/conf/po-foreground.sh:/usr/local/bin/po-foreground.sh"
        ];
        command = [
          "${pkgs.bashInteractive}/bin/sh"
          "/usr/local/bin/po-foreground.sh"
        ];
        inherit networks;
      };
    };

    # What is the best way to get the build Output from the npmlock2nix into this container?
    frontend.service = {
      image = "nginx:stable-alpine";
      depends_on = [ "backend" ];
      volumes = [
        "product_images:/opt/product-opener/html/images/products"
        "html_data:/opt/product-opener/html/data"
        "${toString ./.}/frontend-git/conf/nginx.conf:/etc/nginx/conf.d/default.conf"
      ];
    };
  };
}
