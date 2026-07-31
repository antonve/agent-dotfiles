#!/usr/bin/env bash
# Bootstrap a fresh Debian agent box:
#   curl -fsSL https://raw.githubusercontent.com/antonve/agent-dotfiles/main/bootstrap.sh | bash
#
# Idempotent — safe to re-run. `bootstrap.sh --nix-only` stops after the nix
# install (used for docker layer caching in tests).
set -euo pipefail

REPO_URL="${AGENT_DOTFILES_REPO:-https://github.com/antonve/agent-dotfiles.git}"
# Lives under xdev/personal so the personal git identity applies to this
# (public) repo — see the includeIf in home.nix.
REPO_DIR="$HOME/xdev/personal/agent-dotfiles"

# derive, don't trust, the caller's USER (sudo/su can leave it stale)
USER="$(id -un)"
export USER

log() { printf '\n\033[1;32m==> %s\033[0m\n' "$*"; }

# --- base packages -----------------------------------------------------------
if command -v apt-get >/dev/null; then
  log "installing base apt packages"
  sudo apt-get update -qq
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
    git curl ca-certificates xz-utils locales-all
fi

# --- nix ---------------------------------------------------------------------
if ! command -v nix >/dev/null && [ ! -x /nix/var/nix/profiles/default/bin/nix ] \
    && [ ! -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
  log "installing nix"
  if [ -d /run/systemd/system ]; then
    curl -fsSL https://install.determinate.systems/nix | sh -s -- install --no-confirm
  else
    # containers / no systemd: single-user install
    curl -fsSL https://nixos.org/nix/install | sh -s -- --no-daemon --yes
  fi
fi

# make nix usable in this shell. Prefer the Determinate Nix binary directly:
# its profile script can be a no-op when an inherited guard says it was
# already sourced even though the current PATH no longer contains nix.
if ! command -v nix >/dev/null; then
  if [ -x /nix/var/nix/profiles/default/bin/nix ]; then
    export PATH="/nix/var/nix/profiles/default/bin:$PATH"
  elif [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi
fi

mkdir -p "$HOME/.config/nix"
# match an active (uncommented) line that actually enables flakes
if ! grep -qsE '^\s*experimental-features\s*=.*flakes' "$HOME/.config/nix/nix.conf"; then
  echo 'experimental-features = nix-command flakes' >> "$HOME/.config/nix/nix.conf"
fi

if [ "${1:-}" = "--nix-only" ]; then
  log "nix installed (--nix-only), stopping here"
  exit 0
fi

# --- repo --------------------------------------------------------------------
mkdir -p "$HOME/xdev/personal"
if [ ! -d "$REPO_DIR" ]; then
  log "cloning $REPO_URL"
  git clone "$REPO_URL" "$REPO_DIR"
elif [ -d "$REPO_DIR/.git" ]; then
  log "updating $REPO_DIR"
  git -C "$REPO_DIR" pull --ff-only || echo "warning: could not fast-forward, using local state"
fi

# --- secrets file (untracked) --------------------------------------------------
# Created before the herdr service starts so its EnvironmentFile exists on
# first launch. Perms are (re)tightened on every run.
mkdir -p "$HOME/.config/agentbox"
if [ ! -f "$HOME/.config/agentbox/secrets.env" ]; then
  log "creating ~/.config/agentbox/secrets.env (add your API keys there)"
  install -m 600 "$REPO_DIR/secrets.env.example" "$HOME/.config/agentbox/secrets.env"
fi
chmod 600 "$HOME/.config/agentbox/secrets.env"

# --- git identity (untracked) --------------------------------------------------
# Default identity + override for repos under ~/xdev/personal (see the
# includes in home.nix).
for f in git-identity git-identity-personal; do
  if [ ! -f "$HOME/.config/agentbox/$f" ]; then
    log "creating ~/.config/agentbox/$f (set your git name/email there)"
    install -m 644 "$REPO_DIR/files/$f.example" "$HOME/.config/agentbox/$f"
  fi
done

# --- home-manager switch -----------------------------------------------------
ARCH="$(uname -m)" # x86_64 | aarch64
log "activating home-manager configuration (agent-${ARCH}-linux)"
nix run "$REPO_DIR#home-manager" -- switch \
  --flake "$REPO_DIR#agent-${ARCH}-linux" -b backup --impure

# --- keep herdr alive independent of login sessions ---------------------------
# Done before agentbox-update so a flaky CLI install can't leave the box
# without its herdr service. Deliberately no restart on re-runs: bootstrap
# must never kill a running herdr with live agent sessions.
if [ -d /run/systemd/system ]; then
  log "enabling herdr server at boot (linger + user service)"
  sudo loginctl enable-linger "$USER" \
    || echo "warning: enable-linger failed — herdr will not survive logout/reboot" >&2
  systemctl --user daemon-reload \
    || echo "warning: systemctl --user daemon-reload failed" >&2
  systemctl --user enable --now herdr.service \
    || echo "warning: could not enable/start herdr.service — check 'systemctl --user status herdr'" >&2
else
  echo "no systemd detected — skipping herdr service setup (container?)"
fi

# --- agent CLIs + skills (native installers, self-updating) -------------------
log "installing agent CLIs (claude/codex/opencode/pi) and skills"
HM_BIN="$HOME/.local/state/nix/profiles/home-manager/home-path/bin"
export PATH="$HM_BIN:$PATH"
agentbox-update

log "done. reconnect (or run 'herdr') to attach."
