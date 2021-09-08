{ pkgs, lib, ... }:
let
  inherit (builtins) toString;
  inherit (lib) mkForce makeBinPath;
  # This is a bit hacky... is there a nicer way to do this?
  self = pkgs.self;
  frontendPort = "3000";
  networkName = "webnet";
  networks = [ networkName ];
  volumes = {
    dbdata = null;
    pgdata = null;
    podata = null;
  };
in {
  config = {
    project.name = "openfoodfacts-server";

    docker-compose.raw = {
      networks = { ${networkName} = null; };
      inherit volumes;
    };

    services = {

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
        environment = {
          POSTGRES_PASSWORD = "productopener";
          POSTGRES_USER = "productopener";
          POSTGRES_DB = "minion";
        };
        inherit networks;
      };

      backend = {
        nixos = {
          useSystemd = true;
          configuration = {
            boot.tmpOnTmpfs = true;
            # This clashes with the default setting of an empty string
            networking.hostName = mkForce "productopener";
            services.httpd = {
              enable = true;
              adminAddr = "productopener@example.org";
              enablePerl = true;
            };
            # Copied over from the examples
            # Not sure as to the reason why these are necessary
            services.nscd.enable = false;
            system.nssModules = mkForce [ ];
            environment.systemPackages = [ pkgs.perlWithModules.complete ];
          };
        };
        service = {
          depends_on = [ "mongodb" "memcached" "postgres" ];
          tmpfs = [ "/mnt/podata/mnt" ];
          volumes = [
            "${self}:/opt/product-opener"
            "podata:/mnt/podata"
            "${self}/docker/backend-dev/conf/Config.pm:/opt/product-opener/lib/ProductOpener/Config.pm"
            "${self}/docker/backend-dev/conf/Config2.pm:/opt/product-opener/lib/ProductOpener/Config2.pm"
            "${self}/docker/backend-dev/conf/log.conf:/mnt/podata/log.conf"
            "${self}/docker/backend-dev/conf/minion_log.conf:/mnt/podata/minion_log.conf"
            "${self}/docker/backend-dev/conf/apache.conf:/etc/apache2/sites-enabled/product-opener.conf"
            "${self}/docker/backend-dev/conf/po-foreground.sh:/usr/local/bin/po-foreground.sh"
          ];
          # command = [
          #   "${pkgs.bashinteractive}/bin/sh"
          #   "${toString ./.}/backend-dev/conf/po-foreground.sh"
          # ];
          inherit networks;
        };
      };

      frontend = {
        service = {
          image = "nginx:stable-alpine";
          depends_on = [ "backend" ];
          volumes = [
            "${pkgs.build_npm}:/opt/product-opener/html"
            "${self}/docker/frontend-git/conf/nginx.conf:/etc/nginx/conf.d/default.conf"
          ];
          # Arion "loses" the final CMD in the docker file so that needs to be copied here
          # https://github.com/nginxinc/docker-nginx/blob/f3fe494531f9b157d9c09ba509e412dace54cd4f/stable/alpine/Dockerfile
          command = [ "nginx" "-g" "daemon off;" ];
          ports = [ "${frontendPort}:80" ];
          inherit networks;
        };
      };
    };
  };
}
