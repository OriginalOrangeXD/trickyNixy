{ pkgs, lib, ... }:

# mosh + tmux — the mobile-agent terminal layer.
#
# mosh: roaming SSH that survives IP changes, sleep, and flaky links. It
# bootstraps over SSH (port 22) then runs over its own UDP 60000-61000 range.
# `programs.mosh.enable` installs the package AND opens that UDP range in the
# firewall, so no manual firewall rules are needed. Reached over the LAN or
# the trusted tailscale0 interface.
#
# tmux: session persistence. Interactive remote logins auto-attach a single
# durable session named "main" (attach-or-create), so connecting from the iOS
# mosh terminal drops straight back into the running agent session, and a
# disconnect / phone-sleep never kills it. A personal ~/.tmux.conf still wins
# (it is sourced after the system /etc/tmux.conf this module writes).
#
# Imported by every host so the phone reaches all of them identically.
{
  programs.mosh.enable = true;

  programs.tmux = {
    enable       = true;
    terminal     = "tmux-256color";
    historyLimit = 50000;
    escapeTime   = 10;        # snappier ESC — matters for vim / TUI agents
    keyMode      = "emacs";
    extraConfig  = ''
      set -g mouse on
      set -ga terminal-overrides ",*256col*:Tc"   # truecolor passthrough
    '';
  };

  # Auto-attach a persistent "main" tmux session on interactive login.
  #
  # Guards (all must hold):
  #   $TMUX empty      — don't nest tmux inside tmux
  #   $NO_TMUX empty   — escape hatch: `NO_TMUX=1 ssh host` for a plain shell
  #   stdout is a tty  — skip scp/sftp and `ssh host <cmd>` automation
  #   uid != 0         — leave root logins alone
  #   tmux on PATH     — paranoia
  # `-A` makes new-session attach-or-create, so it's idempotent. No `exec` and
  # no forced exit: if tmux ever fails you simply land in a normal shell rather
  # than getting logged out. Non-interactive automation (BatchMode ssh, the
  # nixos-rebuild activation) never sources this, so deploys are unaffected.
  programs.bash.interactiveShellInit = ''
    if [ -z "$TMUX" ] && [ -z "$NO_TMUX" ] && [ -t 1 ] \
       && [ "$(id -u)" -ne 0 ] && command -v tmux >/dev/null 2>&1; then
      tmux new-session -A -s main
    fi
  '';
}
