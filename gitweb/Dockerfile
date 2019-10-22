FROM alpine

RUN apk add --no-cache git        \
                       lighttpd   \
                       perl-cgi   \
                       openssh    \
                       git-gitweb \
    && ssh-keygen -A \
    && adduser -D -h /srv/git git \
    && echo "git:$(head -c 512 /dev/urandom | sha512sum)" | chpasswd \
    && su git -c "mkdir /srv/git/.ssh && chmod 700 /srv/git/.ssh" \
    && su git -c "touch /srv/git/.ssh/authorized_keys && chmod 600 /srv/git/.ssh/authorized_keys"

    # This is for testing

RUN su git -c "mkdir /srv/git/project.git && cd /srv/git/project.git && git init --bare" \
    && su git -c "echo ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPnlqaYYu3WSCjTsxXNE0P5L3K02bQGYLOVZKdhD0NhJ zuh0@ako >> ~/.ssh/authorized_keys"

    # Remember to remove password auth for ssh and git

    COPY gitweb.conf /etc/gitweb.conf
    COPY lighttpd.conf /etc/lighttpd/lighttpd.conf
    COPY run.sh run.sh

    CMD ["sh", "run.sh"]
