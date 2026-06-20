{ ... }:

# GitLab CE — omnibus container migrated from TrueNAS. Pinned to 17.10.1-ce.0 to
# MATCH the migrated data's schema (data VERSION = 17.10.1). Running a newer
# image forces a skip-version upgrade and crash-loops — which is exactly what it
# was doing on TrueNAS (the image had drifted to :latest). One container, bundled
# postgres/redis/sidekiq. Config/data/logs migrated to /srv/gitlab.
#
# Behind Caddy at https://gitlab.robby.codes: Caddy terminates TLS, and gitlab.rb
# sets GitLab's bundled nginx to plain HTTP on :80, published to the host at
# 127.0.0.1:8929. First boot runs `gitlab-ctl reconfigure` (several minutes
# before the UI answers — the healthcheck stays "starting" until it's ready).
#
# To upgrade later: step through the GitLab upgrade path (17.10 -> 17.11 -> 18.0
# -> ...), never skip a required stop.
{
  virtualisation.oci-containers.containers.gitlab = {
    image    = "gitlab/gitlab-ce:17.10.1-ce.0";
    hostname = "gitlab.robby.codes";
    volumes = [
      "/srv/gitlab/config:/etc/gitlab"
      "/srv/gitlab/logs:/var/log/gitlab"
      "/srv/gitlab/data:/var/opt/gitlab"
    ];
    ports        = [ "127.0.0.1:8929:80" ];
    extraOptions = [ "--shm-size=256m" ];
  };
}
