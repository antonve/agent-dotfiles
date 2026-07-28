{ config, pkgs, lib, herdr, treehouse, ... }:

let
  herdrPkg = herdr.packages.${pkgs.stdenv.hostPlatform.system}.default;
  treehousePkg = treehouse.packages.${pkgs.stdenv.hostPlatform.system}.default;
  agentsMd = ./files/AGENTS.md;

  # Fast-moving agent CLIs are installed via their native installers / npm so
  # they stay current and can self-update; nixpkgs lags them by weeks.
  agentboxUpdate = pkgs.writeShellScriptBin "agentbox-update" ''
    set -euo pipefail
    export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    export PATH="${pkgs.nodejs_24}/bin:$HOME/.npm-global/bin:$HOME/.local/bin:$PATH"

    echo "==> claude code"
    curl -fsSL https://claude.ai/install.sh | bash

    echo "==> codex"
    npm install --global @openai/codex@latest

    echo "==> opencode"
    npm install --global opencode-ai@latest

    echo "==> pi"
    npm install --global --ignore-scripts @earendil-works/pi-coding-agent@latest

    skill() { # skill <repo> <name>
      timeout 300 npx --yes skills add "$1" --skill "$2" -g -y \
        -a claude-code codex opencode pi < /dev/null
    }

    echo "==> herdr agent skill (cross-harness comms, all harnesses)"
    skill ogulcancelik/herdr herdr

    # agent-ergonomic CLI wrappers for the CLIs on this box — deliberately NOT lavish-axi
    echo "==> axi tools (gh, aws, quota) + skills + session hooks"
    npm install --global gh-axi@latest aws-axi@latest quota-axi@latest
    skill kunchenguid/gh-axi gh-axi
    skill kunchenguid/quota-axi quota-axi
    skill bauti-defi/aws-axi aws-axi || echo "warning: aws-axi skill install failed (hooks still cover it)"
    gh-axi setup hooks || echo "warning: gh-axi hook setup failed"
    aws-axi setup hooks || echo "warning: aws-axi hook setup failed"
    # quota-axi has no session hooks; its skill runs it on demand via npx

    # no session links / Co-Authored-By trailers in commits — merged (not
    # written whole) because the axi hooks also edit this file
    echo "==> disabling claude commit/PR attribution"
    mkdir -p "$HOME/.claude"
    if [ -f "$HOME/.claude/settings.json" ]; then
      ${pkgs.jq}/bin/jq '.attribution = {commit: "", pr: ""}' \
        "$HOME/.claude/settings.json" > "$HOME/.claude/settings.json.tmp"
      mv "$HOME/.claude/settings.json.tmp" "$HOME/.claude/settings.json"
    else
      printf '{\n  "attribution": { "commit": "", "pr": "" }\n}\n' \
        > "$HOME/.claude/settings.json"
    fi

    echo "agent box up to date."
  '';

  addSshKey = pkgs.writeShellScriptBin "add-ssh-key" ''
    set -euo pipefail
    key="''${1:-}"
    if [ -z "$key" ] && [ ! -t 0 ]; then
      key="$(cat)"
    fi
    if [ -z "$key" ]; then
      echo 'usage: add-ssh-key "ssh-ed25519 AAAA... user@host"' >&2
      echo '   or: cat id_ed25519.pub | add-ssh-key' >&2
      exit 1
    fi
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    touch "$HOME/.ssh/authorized_keys"
    chmod 600 "$HOME/.ssh/authorized_keys"
    if grep -qxF "$key" "$HOME/.ssh/authorized_keys"; then
      echo "key already present in authorized_keys"
    else
      printf '%s\n' "$key" >> "$HOME/.ssh/authorized_keys"
      echo "key added to authorized_keys"
    fi
  '';
in
{
  # Boxes are per-engineer with arbitrary usernames, so resolve at switch time
  # (requires --impure; bootstrap.sh passes it).
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";
  home.stateVersion = "25.05";

  # non-NixOS host: put ~/.nix-profile/bin etc. on PATH in hm-session-vars
  # (home-manager replaces the ~/.profile the nix installer hooked into)
  targets.genericLinux.enable = true;

  home.packages = with pkgs; [
    herdrPkg
    treehousePkg
    agentboxUpdate
    addSshKey

    # dev tooling
    git
    git-lfs
    gh
    awscli2
    google-cloud-sdk
    nodejs_24
    bun # aws-axi runs on bun
    go
    terraform # plans only — applies run in CI
    ripgrep
    fd
    jq
    fzf
    tree
    htop
    unzip
    file
    util-linux # `column`, used by the `git recent` alias
    gnumake
    gcc # nvim-treesitter compiles parsers

    # language servers for the nvim config (nvim/lua/plugins/lsp.lua)
    gopls
    typescript-language-server
    terraform-ls
    lua-language-server
    nil
  ];

  programs.home-manager.enable = true;

  # diff pager for git (sets core.pager + interactive.diffFilter)
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
    };
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
    # Aliases + shared settings live in files/gitconfig (plain gitconfig, ported
    # from my mac dotfiles). Identity lives in untracked files (bootstrap copies
    # files/git-identity*.example there). Order-sensitive: the personal include
    # must come after the default one so it wins for repos under ~/xdev/personal.
    includes = [
      { path = "${./files/gitconfig}"; }
      { path = "~/.config/agentbox/git-identity"; }
      {
        path = "~/.config/agentbox/git-identity-personal";
        condition = "gitdir:~/xdev/personal/**";
      }
    ];
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    withRuby = false;
    withPython3 = false;
  };

  # nvim config lives in the repo and is symlinked out-of-store so it can be
  # edited without a home-manager switch (lazy.nvim manages the plugins).
  xdg.configFile."nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/xdev/personal/agent-dotfiles/nvim";

  programs.bash = {
    enable = true;
    # ported from my zsh aliases, minus macOS/tmux/kubernetes bits
    shellAliases = {
      # navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      x = "cd ~/xdev";
      cddot = "cd ~/xdev/personal/agent-dotfiles";

      # git (typo-tolerant)
      g = "git";
      got = "git";
      gut = "git";
      gitp = "git";
      gcm = "git commit -m";
      gca = "git commit --amend";

      # shorthands
      h = "history";
      j = "jobs";
      tf = "terraform";
      nuke = "kill -9";

      # ls / grep with color (GNU coreutils)
      ls = "ls --color=auto";
      l = "ls -lF --color=auto";
      la = "ls -laF --color=auto";
      lsd = "ls -lF --color=auto | grep --color=never '^d'";
      grep = "grep --color=auto";
      fgrep = "fgrep --color=auto";
      egrep = "egrep --color=auto";

      # enable alias expansion after sudo
      sudo = "sudo ";

      # utilities
      week = "date +%V";
      timer = ''echo "Timer started. Stop with Ctrl-D." && date && time cat && date'';
      path = ''echo -e ''${PATH//:/\\n}'';
      map = "xargs -n1";
    };
    initExtra = ''
      # bash needs -- for an alias named "-" (shellAliases can't emit it)
      alias -- -='cd -'

      # nix's profile script skips silently when USER is unset (containers)
      export USER="''${USER:-$(id -un)}"

      # herdr panes spawn non-login shells from the systemd service; make sure
      # the home-manager session vars (PATH etc.) are loaded regardless.
      for hm_vars in \
        "$HOME/.local/state/nix/profiles/home-manager/home-path/etc/profile.d/hm-session-vars.sh" \
        "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"; do
        if [ -f "$hm_vars" ]; then . "$hm_vars"; break; fi
      done
      unset hm_vars

      # go install drops binaries here
      export PATH="$HOME/go/bin:$PATH"

      # secrets (API keys) — untracked, see secrets.env.example in the repo
      if [ -f "$HOME/.config/agentbox/secrets.env" ]; then
        set -a
        . "$HOME/.config/agentbox/secrets.env"
        set +a
      fi

      # auto-attach to herdr on interactive SSH sessions.
      # No exec: if herdr crashes or won't start you land in a plain shell
      # instead of being locked out. Opt out with `touch ~/.no-herdr` (env
      # vars don't survive sshd's AcceptEnv filter) or a non-tty command
      # (`ssh box -- bash`).
      if [[ $- == *i* && -n "''${SSH_TTY:-}" && "''${HERDR_ENV:-}" != "1" && -z "''${NO_HERDR:-}" && ! -f "$HOME/.no-herdr" ]] \
          && command -v herdr >/dev/null; then
        herdr
      fi
    '';
  };

  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/.npm-global/bin"
    "$HOME/go/bin"
  ];

  home.file.".npmrc".text = "prefix=\${HOME}/.npm-global\n";

  # One source of truth for global agent instructions, linked into every
  # harness's global location.
  home.file.".claude/CLAUDE.md".source = agentsMd;
  home.file.".codex/AGENTS.md".source = agentsMd;
  home.file.".config/opencode/AGENTS.md".source = agentsMd;
  home.file.".pi/agent/AGENTS.md".source = agentsMd;

  # herdr server as a user service. Combined with `loginctl enable-linger`
  # (done in bootstrap.sh) it starts at boot and survives SSH disconnects and
  # logouts — it is not tied to any login session.
  systemd.user.services.herdr = {
    Unit = {
      Description = "herdr agent multiplexer server";
    };
    Service = {
      ExecStart = "${herdrPkg}/bin/herdr server";
      Restart = "always";
      RestartSec = 2;
      # API keys for the agents running in panes ('-' = optional)
      EnvironmentFile = "-%h/.config/agentbox/secrets.env";
      # Panes inherit this environment; include everything agents need.
      Environment = [
        "PATH=%h/.npm-global/bin:%h/.local/bin:%h/go/bin:%h/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/bin"
      ];
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
  systemd.user.startServices = true;

  # projects folder convention (personal/ gets the personal git identity)
  home.activation.xdevDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/xdev/personal"
  '';
}
