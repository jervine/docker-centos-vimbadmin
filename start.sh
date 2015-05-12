#!/bin/bash
##
## Start up script for httpd on CentOS docker container
##

## Initialise any variables being called:
# Set the correct timezone
TZ=${TZ:-UTC}
setup=/config/httpd/.setup
INSTALL_PATH=${INST:-/data/vmb}

## We always want to set the timezone correctly
rm -f /etc/localtime
cp /usr/share/zoneinfo/$TZ /etc/localtime

## If this is the first time setting things up, we need to download ViMBAdmin and set up the MariaDB dataabase
if [ ! -f "${setup}" ]; then
  mkdir -p $INSTALL_PATH; cd $INSTALL_PATH
  curl -sS https://getcomposer.org/installer | php
  php composer.phar create-project opensolutions/vimbadmin $INSTALL_PATH -s dev
  chown -R apache:apache $INSTALL_PATH/var
  cp $INSTALL_PATH/application/configs/application.ini.dist $INSTALL_PATH/application/configs/application.ini
  cp $INSTALL_PATH/public/.htaccess.dist $INSTALL_PATH/public/.htaccess
  ./bin/doctrine2-cli.php orm:schema-tool:create
  echo "You need to alter the application.ini file to have the correct database settings - and the correct salt information when setting ViMBAdmin up"
  touch $setup
fi

## Start up httpd and postfix daemons via supervisord
/usr/bin/supervisord -n -c /etc/supervisord.conf
