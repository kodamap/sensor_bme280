#!/bin/bash

/usr/sbin/nginx -c /etc/nginx/nginx.conf
tail -f /var/log/nginx/access.log
