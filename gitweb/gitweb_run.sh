#!/bin/sh

lighttpd -f /etc/lighttpd/lighttpd.conf

/usr/sbin/sshd -p 2200 -D
