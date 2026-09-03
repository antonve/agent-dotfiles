#!/usr/bin/env bash
# SSH to the agent box via GCP (gcloud compute ssh over an IAP tunnel) with
# the OAuth callback, Draft web, and T3 Code ports forwarded. Codex and
# OpenCode listen on localhost:1455; Draft on 8765; T3 Code on 8784.
#
# Usage: ./gcloud-ssh-box.sh
#   then inside the box:  codex login  (or  opencode auth login)
#   open the printed OAuth URL, browse to http://127.0.0.1:8765 for Draft,
#   or browse to http://127.0.0.1:8784 for T3 Code.
#
# Box coordinates deliberately live outside the repo: copy
# files/box.env.example to ~/.config/agentbox/box.env on the machine you
# connect FROM, or export AGENTBOX_VM / AGENTBOX_ZONE / AGENTBOX_PROJECT.
set -euo pipefail

if [ -f "$HOME/.config/agentbox/box.env" ]; then
  . "$HOME/.config/agentbox/box.env"
fi

: "${AGENTBOX_VM:?not set — copy files/box.env.example to ~/.config/agentbox/box.env}"
: "${AGENTBOX_ZONE:?not set — copy files/box.env.example to ~/.config/agentbox/box.env}"
: "${AGENTBOX_PROJECT:?not set — copy files/box.env.example to ~/.config/agentbox/box.env}"

# Make it obvious that this terminal tab is attached to the remote agent box.
# CSI 22/23 saves and restores the existing title in xterm-compatible terminals.
title_active=
if [ -t 0 ] || [ -t 1 ]; then
  if printf '\033[22;0t\033]0;REMOTE - agent box\007' > /dev/tty 2>/dev/null; then
    title_active=1
  fi
fi
restore_title() {
  if [ -n "$title_active" ]; then
    printf '\033[23;0t' > /dev/tty 2>/dev/null || true
  fi
}
trap restore_title EXIT

gcloud compute ssh "$AGENTBOX_VM" \
  --zone "$AGENTBOX_ZONE" \
  --project "$AGENTBOX_PROJECT" \
  --tunnel-through-iap \
  -- \
  -L 1455:localhost:1455 \
  -L 8765:localhost:8765 \
  -L 8784:localhost:8784 \
  "$@"
