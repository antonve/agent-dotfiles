FROM debian:12

RUN apt-get update && apt-get install -y --no-install-recommends \
      sudo curl git ca-certificates xz-utils procps \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash agent \
    && echo 'agent ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/agent

USER agent
# docker doesn't set USER, but nix's profile script needs it (sshd sets it on real boxes)
ENV USER=agent
WORKDIR /home/agent

# cache the nix install layer separately from the config
COPY --chown=agent:agent bootstrap.sh /tmp/bootstrap.sh
RUN bash /tmp/bootstrap.sh --nix-only

COPY --chown=agent:agent . xdev/personal/agent-dotfiles
RUN bash xdev/personal/agent-dotfiles/bootstrap.sh

RUN bash -lc 'bash ~/xdev/personal/agent-dotfiles/test/verify.sh'
