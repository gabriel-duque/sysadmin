FROM dutchcoders/transfer.sh:latest

ENTRYPOINT [ "/go/bin/transfersh",                             \
             "--listener", ":80",                              \
             "--provider", "local",                            \
             "--basedir", "/tmp",                              \
             "--log", "/lapras.log"                            \
]

EXPOSE 80/tcp
