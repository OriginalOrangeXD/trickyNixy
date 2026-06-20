{ config, lib, pkgs, ... }:

# Shared identity for every media-related service that lands on this box.
# Jellyfin, Sonarr, Radarr, Bazarr, Prowlarr, qBittorrent — all run as
# `media:media` and all write into /srv/media owned by the same user.
#
# Why one user instead of per-service users:
#   The arr stack writes downloads that Jellyfin reads. Per-service users
#   demand a shared group + careful umask/setgid handling on every dataset.
#   One shared user collapses that surface to a single ownership/mode rule.
#
# Stable UID/GID 10000 lets us declare ownership of /srv/media files
# deterministically across rebuilds.
{
  users.groups.media = {
    gid = 10000;
  };

  users.users.media = {
    isSystemUser = true;
    uid          = 10000;
    group        = "media";
    description  = "Shared identity for media services (Jellyfin, *arr, etc.)";
    home         = "/var/empty";

    # video/render — for hardware-accelerated transcoding via /dev/nvidia*
    # and /dev/dri/* device nodes.
    extraGroups = [ "video" "render" ];
  };

  # Ensure /srv/media exists and is owned by media:media at activation time.
  # Subdirs created by the migrated bare/media datasets (movies, tvshows,
  # anime, family, music, …) need a one-time `chown` after `media` exists —
  # that's a manual step in the runbook, not declarative (we don't want
  # NixOS chowning huge ZFS trees on every activation).
  systemd.tmpfiles.rules = [
    "d /srv/media 0775 media media -"
  ];
}
