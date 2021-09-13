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
    product_images = null;
    html_data = null;
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
            networking.firewall.allowedTCPPorts = [ 80 ];
            networking.firewall.allowedUDPPorts = [ 80 ];
            environment.systemPackages = with pkgs; [
              busybox
              perlWithModules.complete
              imagemagick
              graphviz
              tesseract
              gnumeric
            ];
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
              extraConfig = ''
                # Apache + mod_perl handles only the dynamic HTML generated pages
                # and CGI scripts.
                # Static files are served directly by the NGINX reverse proxy.

                ServerAdmin contact@productopener.localhost

                PerlSwitches -I/opt/product-opener/lib -I${pkgs.perlWithModules.complete}/lib/perl5/site_perl

                PerlWarn On

                <IfDefine PERLDB>

                  PerlSetEnv PERLDB_OPTS "RemotePort=socat:53505"

                  <Perl>
                    use APR::Pool ();
                    use Apache::DB ();
                    Apache::DB->init();
                  </Perl>

                  <Location />
                    PerlFixupHandler Apache::DB
                  </Location>

                </IfDefine>

                PerlRequire /opt/product-opener/lib/startup_apache2.pl

                # log the X-Forwarded-For IP address (the client ip) in access_log
                LogFormat "%{X-Forwarded-For}i %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" proxy

                <Location /cgi>
                  SetHandler perl-script
                  PerlResponseHandler ModPerl::Registry
                  PerlOptions +ParseHeaders
                  Options +ExecCGI
                  Require all granted
                </Location>

                <VirtualHost *>
                  DocumentRoot /opt/product-opener/html
                  ServerName productopener.localhost
                  LogLevel warn
                  ScriptAlias /cgi/ "/opt/product-opener/cgi/"

                  <Directory /opt/product-opener/html>
                    Require all granted
                  </Directory>

                </VirtualHost>

                PerlPostReadRequestHandler get_remote_proxy_address
              '';
            };
            # Copied over from the examples
            # Not sure as to the reason why these are necessary
            services.nscd.enable = false;
            system.nssModules = mkForce [ ];
            systemd.services.startup = {
              script = ''
                mkdir -p /mnt/podata/products /mnt/podata/logs /mnt/podata/users /mnt/podata/po /mnt/podata/orgs

                if [ ! -e /mnt/podata/lang ]
                then
                  ln -sf /opt/product-opener/lang /mnt/podata/lang
                fi

                if [ ! -e /mnt/podata/po/common ]
                then
                  ln -sf /opt/product-opener/po/common /mnt/podata/po/common
                fi

                if [ ! -e /mnt/podata/po/site-specific ]
                then
                  ln -sf /opt/product-opener/po/openfoodfacts /mnt/podata/po/site-specific
                fi

                if [ ! -e /mnt/podata/po/tags ]
                then
                  ln -sf /opt/product-opener/po/tags /mnt/podata/po/tags
                fi

                if [ ! -e /mnt/podata/taxonomies ]
                then
                  ln -sf /opt/product-opener/taxonomies /mnt/podata/taxonomies
                fi

                if [ ! -e /mnt/podata/ingredients ]
                then
                  ln -sf /opt/product-opener/ingredients /mnt/podata/ingredients
                fi

                if [ ! -e /mnt/podata/emb_codes ]
                then
                  ln -sf /opt/product-opener/emb_codes /mnt/podata/emb_codes
                fi

                if [ ! -e /mnt/podata/packager-codes ]
                then
                  ln -sf /opt/product-opener/packager-codes /mnt/podata/packager-codes
                fi

                if [ ! -e /mnt/podata/ecoscore ]
                then
                  ln -sf /opt/product-opener/ecoscore /mnt/podata/ecoscore
                fi

                if [ ! -e /mnt/podata/forest-footprint ]
                then
                  ln -sf /opt/product-opener/forest-footprint /mnt/podata/forest-footprint
                fi

                if [ ! -e /mnt/podata/templates ]
                then
                  ln -sf /opt/product-opener/templates /mnt/podata/templates
                fi

                ${pkgs.perlWithModules.complete}/bin/perl -I/opt/product-opener/lib /opt/product-opener/scripts/build_lang.pl
                chown -R www-data:www-data /mnt/podata
                chown -R www-data:www-data /opt/product-opener/html/images/products

              '';
              before = [ "httpd.service" ];
              wantedBy = [ "multi-user.target" ];
            };
          };
        };
        service = {
          depends_on = [ "mongodb" "memcached" "postgres" ];
          tmpfs = [ "/mnt/podata/mnt" ];
          volumes = [
            "${self}:/opt/product-opener"
            "podata:/mnt/podata"
            "product_images:/opt/product-opener/html/images/products"
            "html_data:/opt/product-opener/html/data"
            "${self}/docker/backend-dev/conf/Config.pm:/opt/product-opener/lib/ProductOpener/Config.pm"
            "${self}/docker/backend-dev/conf/Config2.pm:/opt/product-opener/lib/ProductOpener/Config2.pm"
            "${self}/docker/backend-dev/conf/log.conf:/mnt/podata/log.conf"
            "${self}/docker/backend-dev/conf/minion_log.conf:/mnt/podata/minion_log.conf"
            # "${self}/docker/backend-dev/conf/apache.conf:/etc/apache2/sites-enabled/product-opener.conf"
            # "${self}/docker/backend-dev/conf/po-foreground.sh:/usr/local/bin/po-foreground.sh"
          ];
          inherit networks;
        };
      };

      frontend = {
        service = {
          image = "nginx:stable-alpine";
          depends_on = [ "backend" ];
          volumes = [
            "product_images:/opt/product-opener/html/images/products"
            "html_data:/opt/product-opener/html/data"
            "${self}/html:/opt/product-opener/html"
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
