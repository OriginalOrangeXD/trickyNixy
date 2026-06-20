# agenix recipient list — every encrypted secret in this directory is
# encrypted to ALL keys listed here. Replace the placeholders with real
# pubkeys before running `agenix -e`.
#
# Get your local laptop's pubkey:    cat ~/.ssh/id_ed25519.pub
# Get the homeserver's host pubkey:  ssh robby@192.168.1.254 'cat /etc/ssh/ssh_host_ed25519_key.pub'
#
# The host key matters because the running NixOS box uses it to decrypt
# secrets at boot — without it, the systemd unit can't read the HA token.

let
  # Personal keys (one per machine you want to be able to edit secrets from).
  robby-laptop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG7WQgXfplk8FlV5CgyKxHaLRpTMtJcyct3s6ADdOYJ9 robby@Roberts-MacBook-Pro.local";

  # Host keys (machines that need to read the secrets at runtime).
  # Pubkey verified live: `ssh robby@192.168.1.254 cat /etc/ssh/ssh_host_ed25519_key.pub`
  homeserver   = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJqcxwmYIhOL8O1vyr4zFn0L1cfNLyU4SfSY3hcJBXS2 root@nixos";
  # Pubkey verified live: `ssh robby@192.168.1.10 cat /etc/ssh/ssh_host_ed25519_key.pub`
  mediaserver  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINgujh7h+W7cYOga1Shb3o1yKVx3P6WicvyDrSlNBgQ3 root@nixos";
  # Pubkey verified live: `ssh robby@192.168.1.79 cat /etc/ssh/ssh_host_ed25519_key.pub`
  agentbox     = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC9bWG4dBVhrgTVsAQgbGB63ZCl0o+T8G/QfaeffbcZr root@nixos";

  users = [ robby-laptop ];
  hosts = [ homeserver mediaserver agentbox ];
in
{
  "ha-token.age" = {
    publicKeys = users ++ [ homeserver ];
  };

  # Cloudflare API token (Zone:DNS:Edit on robby.codes) for Caddy's ACME
  # DNS-01 challenge on the mediaserver. Decrypts to a single line:
  #   CF_API_TOKEN=<token>
  # consumed as an EnvironmentFile by the caddy systemd unit.
  "cloudflare-dns-token.age" = {
    publicKeys = users ++ [ mediaserver ];
  };

  # Cloudflare Tunnel connector token (Zero Trust → Tunnels) for remote
  # access to Jellyfin. Decrypts to a single line:
  #   TUNNEL_TOKEN=<token>
  # consumed as an EnvironmentFile by the cloudflared systemd unit.
  "cloudflared-token.age" = {
    publicKeys = users ++ [ mediaserver ];
  };

  # WireGuard client config for the download VPN namespace (wg_client).
  # `wg setconf` format — NOT wg-quick. Decrypts to:
  #   [Interface]
  #   PrivateKey = <client private key>
  #   [Peer]
  #   PublicKey = <server public key>
  #   Endpoint = <server ip>:51820
  #   AllowedIPs = 0.0.0.0/0
  # (Address + DNS are NOT in here — they're set as privateIP/dnsIP in
  # modules/wireguard-netns.nix.)
  "wg-client.age" = {
    publicKeys = users ++ [ mediaserver ];
  };

  # PAI credentials store for the agentbox DA. Plaintext is the laptop's
  # ~/.claude/PAI/USER/Config/PAI_CONFIG.yaml (API keys etc.). Decrypted at
  # activation and installed into the PAI tree by modules/pai.nix — it is
  # gitignored in the PAI repo, so it never lives in plaintext anywhere git
  # can see. Re-encrypt with `agenix -e pai-config.age` from a host with a key.
  "pai-config.age" = {
    publicKeys = users ++ [ agentbox ];
  };
}
