# Dockerfile for git.zuh0.com
FROM alpine

RUN apk add --no-cache git        \
                       lighttpd   \
                       cgit       \
                       openssh    \
    && ssh-keygen -A \
    && adduser -D -h /srv/git -s /usr/bin/git-shell git \
    && echo "git:$(head -c 512 /dev/urandom | sha512sum)" | chpasswd \
    && mkdir /srv/git/.ssh \
    && chmod 700 /srv/git/.ssh \
    && touch /srv/git/.ssh/authorized_keys \
    && chmod 600 /srv/git/.ssh/authorized_keys \
    && chown -R 'git:git' /srv/git/.ssh \
    && echo 'include "cgit.conf"' >> /etc/lighttpd/lighttpd.conf

COPY cgitrc /etc/cgitrc
COPY cgit.conf /etc/lighttpd/cgit.conf
COPY gengar.sh gengar.sh

COPY git-shell-commands "/srv/git/git-shell-commands"

EXPOSE 8000/tcp
EXPOSE 4443/tcp
EXPOSE 2200/tcp

CMD ["sh", "gengar.sh"]
