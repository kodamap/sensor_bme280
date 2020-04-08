#!/bin/bash

/usr/sbin/cron -f &
/usr/sbin/nginx -g 'daemon off;'
