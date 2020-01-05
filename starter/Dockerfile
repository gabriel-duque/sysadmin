FROM alpine:latest

ARG pass
ARG port

RUN apk add --no-cache python3 openssh \
    && ssh-keygen -A \
    && echo 'root:'$pass | chpasswd \
    && mkdir site \
    && sed -i.orig -e 's/^#Port.*/Port '$port'/' \
                   -e 's/^#PermitRootLogin.*/PermitRootLogin yes/' \
                   /etc/ssh/sshd_config

COPY starter.sh .

ENTRYPOINT [ "sh", "starter.sh" ]

EXPOSE 80/tcp
EXPOSE $port/tcp
