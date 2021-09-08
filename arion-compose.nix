{ pkgs, lib, ... }:
let
  inherit (builtins) toString;
  inherit (lib) mkForce makeBinPath;
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
            # "${toString ./.}:/opt/product-opener"
            "podata:/mnt/podata"
            # "${toString ./.}/backend-dev/conf/log.conf:/mnt/podata/log.conf"
            # "${toString ./.}/backend-dev/conf/minion_log.conf:/mnt/podata/minion_log.conf"
            # "${toString ./.}/backend-dev/conf/apache.conf:/etc/apache2/sites-enabled/product-opener.conf"
          ];
          # command = [
          #   "${pkgs.bashinteractive}/bin/sh"
          #   "${toString ./.}/backend-dev/conf/po-foreground.sh"
          # ];
          inherit networks;
        };
      };

      frontend.service = {
        image = "nginx:stable-alpine";
        depends_on = [ "backend" ];
        volumes = [
          "${toString ./.}/html:/opt/product-opener/html"
          "${
            toString ./.
          }/frontend-git/conf/nginx.conf:/etc/nginx/conf.d/default.conf"
        ];
        inherit networks;
      };
    };
  };
}
