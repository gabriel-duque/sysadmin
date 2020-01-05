#!/bin/sh

python3 -m http.server -d site 80 &
/usr/sbin/sshd -D
