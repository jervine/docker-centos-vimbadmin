#!/bin/bash
##
## Start up script for httpd on CentOS docker container
##

## Initialise any variables being called:
# Set the correct timezone
TZ=${TZ:-UTC}
setup=/config/httpd/.setup

if [ ! -f "${setup}" ]; then
  rm -f /etc/localtime
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  touch $setup
fi

## Start up httpd and postfix daemons via supervisord
/usr/bin/supervisord -n -c /etc/supervisord.conf
