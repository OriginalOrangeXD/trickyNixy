{ ... }:

# Vaultwarden — self-hosted Bitwarden-compatible password manager. Native
# nixpkgs module (services.vaultwarden), sqlite backend. Migrated from the old
# TrueNAS container (vaultwarden/server:latest): a consistent SQLite .backup of
# the live db (1 user, 65 ciphers) + rsa_key.pem are dropped into the service's
# data dir post-deploy.
#
# Rocket listens on localhost:8222; Caddy terminates TLS and reverse-proxies
# https://vault.robby.codes (incl. the /notifications/hub websocket). DOMAIN
# matches the old instance so existing clients/links keep working after the
# UniFi DNS record is pointed at this box.
{
  services.vaultwarden = {
    enable    = true;
    dbBackend = "sqlite";
    config = {
      DOMAIN          = "https://vault.robby.codes";
      SIGNUPS_ALLOWED = false;        # accounts already exist; no open signup
      ROCKET_ADDRESS  = "127.0.0.1";
      ROCKET_PORT     = 8222;
    };
  };
}
