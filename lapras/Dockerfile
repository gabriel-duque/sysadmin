FROM dutchcoders/transfer.sh:latest

ENTRYPOINT [ "/go/bin/transfersh",                             \
             "--listener", ":80",                              \
             "--provider", "local",                            \
             "--basedir", "/tmp",                              \
             "--tls-listener", ":443",                         \
             "--tls-cert-file", "/certs/files.zuh0.com.crt",   \
             "--tls-private-key", "/certs/files.zuh0.com.key", \
             "--log", "/lapras.log"                            \
]

EXPOSE 80/tcp
EXPOSE 443/tcp
