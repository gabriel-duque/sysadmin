#!/bin/sh

lighttpd -f /etc/lighttpd/lighttpd.conf

/usr/sbin/sshd -D
