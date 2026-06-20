{ pkgs, lib, ... }:

# Immich — self-hosted photo management. No nixpkgs module: the old instance ran
# the pgvecto-rs vector DB and is ~14 months old, so pulling current Immich would
# force a risky pgvecto-rs->pgvector DB migration. Instead we replicate the EXACT
# same 4-container stack as OCI containers, with the immich-server/ML images
# copied from TrueNAS and pinned to local-only tags (immich-local/*:mig) so they
# can never be silently upgraded. Data migrated onto the spinning pool:
#
#   library  /srv/immich/library  -> server   /usr/src/app/upload   (156G, zfs recv)
#   pgdata   /srv/immich/pgdata   -> postgres  /var/lib/postgresql/data
#   creds    /var/lib/immich/db.env  (DB_PASSWORD/POSTGRES_PASSWORD — kept off git)
#
# Caddy fronts https://immich.robby.codes -> 127.0.0.1:2283. Upgrade Immich later
# deliberately (stepwise) once this boots clean.
let
  netUnit = "docker-network-immich.service";
in
{
  # User-defined bridge so the four containers resolve each other by name.
  systemd.services.docker-network-immich = {
    description = "Create the immich docker network";
    after      = [ "docker.service" ];
    requires   = [ "docker.service" ];
    wantedBy   = [ "multi-user.target" ];
    path       = [ pkgs.docker ];
    serviceConfig = { Type = "oneshot"; RemainAfterExit = true; };
    script = "docker network inspect immich >/dev/null 2>&1 || docker network create immich";
  };

  virtualisation.oci-containers.containers = {
    immich-postgres = {
      image = "docker.io/tensorchord/pgvecto-rs:pg14-v0.2.0";
      cmd = [
        "postgres"
        "-c" "shared_preload_libraries=vectors.so"
        "-c" ''search_path="$user", public, vectors''
        "-c" "logging_collector=on"
        "-c" "max_wal_size=2GB"
        "-c" "shared_buffers=512MB"
        "-c" "wal_compression=on"
      ];
      environment = {
        POSTGRES_USER        = "postgres";
        POSTGRES_DB          = "immich";
        POSTGRES_INITDB_ARGS = "--data-checksums";
      };
      environmentFiles = [ "/var/lib/immich/db.env" ];
      volumes      = [ "/srv/immich/pgdata:/var/lib/postgresql/data" ];
      extraOptions = [ "--network=immich" ];
    };

    immich-redis = {
      image        = "docker.io/redis:6.2-alpine";
      extraOptions = [ "--network=immich" ];
    };

    immich-machine-learning = {
      image        = "immich-local/ml:mig";
      volumes      = [ "/var/lib/immich/model-cache:/cache" ];
      extraOptions = [ "--network=immich" ];
    };

    immich-server = {
      image = "immich-local/server:mig";
      environment = {
        DB_HOSTNAME      = "immich-postgres";
        DB_USERNAME      = "postgres";
        DB_DATABASE_NAME = "immich";
        REDIS_HOSTNAME   = "immich-redis";
      };
      environmentFiles = [ "/var/lib/immich/db.env" ];
      volumes = [
        "/srv/immich/library:/usr/src/app/upload"
        "/etc/localtime:/etc/localtime:ro"
      ];
      ports        = [ "2283:2283" ];
      dependsOn    = [ "immich-postgres" "immich-redis" ];
      extraOptions = [ "--network=immich" ];
    };
  };

  # Each container must wait for the bridge network to exist.
  systemd.services.docker-immich-postgres         = { after = [ netUnit ]; requires = [ netUnit ]; };
  systemd.services.docker-immich-redis            = { after = [ netUnit ]; requires = [ netUnit ]; };
  systemd.services.docker-immich-machine-learning = { after = [ netUnit ]; requires = [ netUnit ]; };
  systemd.services.docker-immich-server           = { after = [ netUnit ]; requires = [ netUnit ]; };

  # Expose Immich's web/API port on the LAN for direct access at
  # http://192.168.1.10:2283 (alongside the Cloudflare tunnel + Caddy paths).
  networking.firewall.allowedTCPPorts = [ 2283 ];
}
