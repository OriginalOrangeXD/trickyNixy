{ config, lib, pkgs, ... }:

# PAI (Personal AI Infrastructure) on agentbox — "Model B" hybrid.
#
# Division of labour (see also the PAI repo's README):
#   • Nix owns the ENVIRONMENT — the runtime binaries PAI's skills shell out
#     to, plus the one live secret (PAI_CONFIG.yaml via agenix), plus a
#     one-time bootstrap that adopts ~/.claude into the PAI git repo.
#   • Git owns PAI ITSELF — the framework, skills, hooks, agents, memory and
#     identity all live in the private repo github.com/OriginalOrangeXD/PAI
#     and are kept current with plain `git pull` / `git push`. Nix does NOT
#     re-deploy PAI; you never need `nix flake update` to ship a skill.
#   • Claude Code is what actually runs, reading the files git put in place.
#
# Day-to-day:  edit on the laptop → git push → `git pull` here.   No rebuild.
# Occasional:  a skill needs a NEW binary → add it to paiPackages below →
#              nixos-rebuild.  (This list is the one seam between the two
#              worlds: a skill that only uses bun/TS or tools already here
#              needs nothing from Nix.)
#
# This box is a REPLICA/consumer of the laptop's PAI (same repo, same
# identity). If it should ever diverge into its own DA, give it its own
# branch or repo — not in scope here.

let
  user   = "robby";
  home   = "/home/${user}";
  claude = "${home}/.claude";
  # Private PAI repo. agentbox's user SSH key is already registered on the
  # GitHub account, so this clones with no extra deploy key.
  paiRepo = "git@github.com:OriginalOrangeXD/PAI.git";
in
{
  # ── Runtime binaries PAI skills expect on PATH ─────────────────────────────
  # bun + git + claude-code are already provided by the host config; this adds
  # the rest of the common skill toolbelt. Grow this list as skills need it.
  environment.systemPackages = with pkgs; [
    nodejs                 # some MCP servers / tools still want node (PAI itself is bun)
    git
    ripgrep                # rg — used heavily by PAI search + Robert's prefs
    fd
    bat
    jq
    tree
    openssh                # git-over-ssh for the bootstrap clone
  ];

  # ── The one live secret: PAI_CONFIG.yaml (API keys etc.) ───────────────────
  # Decrypted at activation to /run/agenix/pai-config, readable by robby. The
  # pai-setup service below copies it into the PAI tree (which is gitignored
  # there, so it never lands in the repo). Encrypted to robby-laptop + this
  # host's key in secrets/secrets.nix.
  age.secrets.pai-config = {
    file  = ../secrets/pai-config.age;
    owner = user;
    group = "users";
    mode  = "0400";
  };

  # ── Bootstrap: adopt ~/.claude into the PAI repo, install the secret ────────
  # Runs as robby on every activation, but the destructive initial checkout
  # happens ONCE (guarded on "no HEAD yet"). After that, ~/.claude is a normal
  # git clone you drive by hand — Nix never force-touches your working tree.
  # Claude Code's own runtime files (.credentials.json, projects/, plugins/,
  # caches) are gitignored in the repo, so the adoption never clobbers them.
  systemd.services.pai-setup = {
    description = "Provision PAI tree into ~/.claude (clone-once) + install PAI_CONFIG.yaml";
    after       = [ "network-online.target" ];
    wants       = [ "network-online.target" ];
    wantedBy    = [ "multi-user.target" ];
    path        = [ pkgs.git pkgs.openssh pkgs.coreutils ];

    serviceConfig = {
      Type            = "oneshot";
      User            = user;
      Group           = "users";
      RemainAfterExit = true;
      Environment     = "HOME=${home}";
    };

    script = ''
      set -eu

      # 1. One-time adoption of ~/.claude into the PAI repo.
      mkdir -p "${claude}"
      cd "${claude}"
      [ -d .git ] || git init -q -b main
      git remote get-url origin >/dev/null 2>&1 || git remote add origin "${paiRepo}"

      if ! git rev-parse --verify -q HEAD >/dev/null 2>&1; then
        # First run only: fetch and force the working tree to match main.
        # Force is safe — tracked files get the repo's version, untracked
        # Claude Code runtime files are gitignored and left untouched.
        GIT_SSH_COMMAND="ssh -o StrictHostKeyChecking=accept-new -o BatchMode=yes" \
          git fetch -q origin main
        git checkout -f -B main origin/main
      fi

      # 2. Every activation: drop the decrypted PAI_CONFIG.yaml into place.
      #    (It is gitignored in the repo, so this never affects git status.)
      install -d -m 0700 -o ${user} -g users "${claude}/PAI/USER/Config"
      install -m 0600 -o ${user} -g users \
        "${config.age.secrets.pai-config.path}" \
        "${claude}/PAI/USER/Config/PAI_CONFIG.yaml"
    '';
  };
}
