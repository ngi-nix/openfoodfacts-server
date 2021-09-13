{ pkgs, lib, ... }:
let
  inherit (builtins) toString;
  inherit (lib) mkForce makeBinPath;
  # This is a bit hacky... is there a nicer way to do this?
  self = pkgs.self;
  backendHostname = "productopener";
  frontendPort = "80";
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
        command = [ "mongod" ];
      };

      memcached.service = {
        image = "memcached:1.6-alpine";
        inherit networks;
        command = [ "memcached" ];
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
        command = [ "postgres" ];
      };

      backend = {
        nixos = {
          useSystemd = true;
          configuration = {
            boot.tmpOnTmpfs = true;
            # This clashes with the default setting of an empty string
            networking.hostName = mkForce backendHostname;
            users = {
              mutableUsers = false;
              users.root.password = "password";
              users."www-data" = {
                isSystemUser = true;
                group = "www-data";
                uid = 500;
              };
              groups."www-data" = { gid = 501; };
            };
            services.httpd = {
              enable = true;
              user = "www-data";
              group = "www-data";
              adminAddr = "productopener@example.org";
              enablePerl = true;
            };
            # Copied over from the examples
            # Not sure as to the reason why these are necessary
            services.nscd.enable = false;
            system.nssModules = mkForce [ ];
          };
        };
        image.contents = with pkgs; [ busybox perlWithModules.complete ];
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
          # grrrr:
          # backend_1    | /usr/local/bin/po-foreground.sh: line 2: mkdir: not found
          # backend_1    | /usr/local/bin/po-foreground.sh: line 59: perl: not found
          # backend_1    | /usr/local/bin/po-foreground.sh: line 60: chown: not found
          # backend_1    | /usr/local/bin/po-foreground.sh: line 61: chown: not found
          # backend_1    | /usr/local/bin/po-foreground.sh: line 67: rm: not found
          # This cannot find any of the environment system packages?
          # Do I need to call it with a paritcular shell?
          # command = [ "/bin/sh" "/usr/local/bin/po-foreground.sh" ];
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
